"""Newsletter subscription storage.

Uses SQLite for local/simple hosting.  To switch databases later, replace
the ``SubscriptionStore`` implementation — the rest of the app talks only
to the public interface (``add_subscriber``, ``subscriber_exists``,
``subscriber_count``).
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterator

# Default database path — sits next to this file.
_DB_PATH: Path = Path(__file__).resolve().parent / "data" / "pyxle.db"


def _ensure_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


@contextmanager
def _connect(db_path: Path | None = None) -> Iterator[sqlite3.Connection]:
    path = db_path or _DB_PATH
    _ensure_dir(path)
    conn = sqlite3.connect(str(path))
    conn.execute("PRAGMA journal_mode=WAL")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def _init_tables(db_path: Path | None = None) -> None:
    with _connect(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS subscribers (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                email       TEXT    NOT NULL UNIQUE COLLATE NOCASE,
                subscribed_at TEXT  NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS playground_reactions (
                emoji TEXT PRIMARY KEY,
                count INTEGER NOT NULL DEFAULT 0
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS playground_stats (
                key   TEXT PRIMARY KEY,
                value INTEGER NOT NULL DEFAULT 0
            )
            """
        )


# Ensure tables exist on first import.
_init_tables()


# ── Public API ────────────────────────────────────────────────


def add_subscriber(email: str, *, db_path: Path | None = None) -> bool:
    """Insert a new subscriber.  Returns ``True`` on success, ``False`` if
    the email already exists."""
    now = datetime.now(tz=timezone.utc).isoformat()
    try:
        with _connect(db_path) as conn:
            conn.execute(
                "INSERT INTO subscribers (email, subscribed_at) VALUES (?, ?)",
                (email, now),
            )
        return True
    except sqlite3.IntegrityError:
        return False


def subscriber_exists(email: str, *, db_path: Path | None = None) -> bool:
    with _connect(db_path) as conn:
        row = conn.execute(
            "SELECT 1 FROM subscribers WHERE email = ?", (email,)
        ).fetchone()
    return row is not None


def subscriber_count(*, db_path: Path | None = None) -> int:
    with _connect(db_path) as conn:
        row = conn.execute("SELECT COUNT(*) FROM subscribers").fetchone()
    return row[0] if row else 0


def get_all_subscribers(*, db_path: Path | None = None) -> list[dict]:
    """Return all subscribers ordered by most recent first."""
    with _connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            "SELECT id, email, subscribed_at FROM subscribers ORDER BY subscribed_at DESC"
        ).fetchall()
    return [dict(row) for row in rows]


# ── Playground API ───────────────────────────────────────────


def increment_reaction(emoji: str, *, db_path: Path | None = None) -> int:
    """Atomically increment the reaction count for *emoji* and return the new count."""
    with _connect(db_path) as conn:
        row = conn.execute(
            "INSERT INTO playground_reactions (emoji, count) VALUES (?, 1) "
            "ON CONFLICT(emoji) DO UPDATE SET count = count + 1 "
            "RETURNING count",
            (emoji,),
        ).fetchone()
    return row[0] if row else 1


def get_reactions(*, db_path: Path | None = None) -> dict[str, int]:
    """Return ``{emoji: count}`` for all recorded reactions."""
    with _connect(db_path) as conn:
        rows = conn.execute(
            "SELECT emoji, count FROM playground_reactions"
        ).fetchall()
    return {row[0]: row[1] for row in rows}


def get_client_ip(request: object) -> str:
    """Return the real client IP for rate-limit bucketing.

    Production traffic flows ``browser -> Cloudflare -> nginx -> Starlette``.
    Starlette's ``request.client.host`` shows the immediate peer -- the
    local nginx proxy or the Cloudflare edge -- which is useless for
    per-visitor rate limiting because:

    - Cloudflare edges rotate across requests, so a single user can fan
      out across many edge IPs within seconds.
    - Every visitor on the site shares the same nginx proxy IP (127.0.0.1
      from Starlette's perspective).

    The only trustworthy real-IP signal on a Cloudflare-fronted origin is
    the ``CF-Connecting-IP`` header, which Cloudflare sets on every
    request and scrubs if the client sends it themselves. ``X-Forwarded-For``
    is a reasonable secondary fallback for other reverse proxies; its
    leftmost entry is the original client. ``request.client.host`` is the
    last-resort fallback for local development, where neither header is
    set and the user IS the peer.

    Returns ``"unknown"`` only as a final safety net; callers pass the
    return value straight into ``check_rate_limit`` as the bucket key.
    """

    headers = getattr(request, "headers", None)
    if headers is not None:
        cf_ip = headers.get("cf-connecting-ip")
        if cf_ip:
            cf_ip = cf_ip.strip()
            if cf_ip:
                return cf_ip
        forwarded = headers.get("x-forwarded-for")
        if forwarded:
            # ``X-Forwarded-For: client, proxy1, proxy2`` -- the leftmost
            # entry is the original client.
            first = forwarded.split(",")[0].strip()
            if first:
                return first
    client = getattr(request, "client", None)
    host = getattr(client, "host", None) if client is not None else None
    return host or "unknown"


def _ensure_rate_limits_schema(conn: sqlite3.Connection) -> None:
    """Create or migrate the ``rate_limits`` table to the current schema.

    Each row represents a single action call from a single IP against a
    named scope (e.g. ``click_home``, ``subscribe_newsletter``). The
    ``scope`` column lets every feature run an independent bucket so
    exhausting the home clicker doesn't lock the user out of the
    newsletter or reactions.

    Legacy databases from before the scope column was added get migrated
    in place with an ``ALTER TABLE ADD COLUMN``; existing rows are
    implicitly migrated into the empty ``""`` scope (harmless -- they'll
    be GC'd within the hour alongside the active buckets).
    """

    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS rate_limits (
            ip           TEXT NOT NULL,
            attempted_at TEXT NOT NULL,
            scope        TEXT NOT NULL DEFAULT ''
        )
        """
    )
    existing_columns = {row[1] for row in conn.execute("PRAGMA table_info(rate_limits)")}
    if "scope" not in existing_columns:
        conn.execute(
            "ALTER TABLE rate_limits ADD COLUMN scope TEXT NOT NULL DEFAULT ''"
        )


def check_rate_limit(
    ip: str,
    *,
    scope: str,
    max_attempts: int = 5,
    window_seconds: int = 3600,
    db_path: Path | None = None,
) -> bool:
    """Return ``True`` if the IP is within the rate limit for *scope*, ``False`` if blocked.

    Every caller must pass an explicit ``scope`` string identifying the
    feature being rate-limited (e.g. ``"click_home"``). Buckets are
    independent per ``(ip, scope)`` tuple, so exhausting one feature's
    quota never spills over into another.

    The helper opportunistically GCs rows older than the rolling window
    across all scopes at the start of every call, so a scope that sees
    any traffic also cleans up its siblings. The out-of-band cleanup in
    ``scripts/cleanup_rate_limits.py`` exists to handle scopes that
    haven't been touched recently.
    """

    with _connect(db_path) as conn:
        _ensure_rate_limits_schema(conn)

        now = datetime.now(tz=timezone.utc)
        cutoff_iso = (now - timedelta(seconds=window_seconds)).isoformat()

        conn.execute(
            "DELETE FROM rate_limits WHERE attempted_at < ?",
            (cutoff_iso,),
        )
        row = conn.execute(
            "SELECT COUNT(*) FROM rate_limits "
            "WHERE ip = ? AND scope = ? AND attempted_at >= ?",
            (ip, scope, cutoff_iso),
        ).fetchone()
        if row and row[0] >= max_attempts:
            return False
        conn.execute(
            "INSERT INTO rate_limits (ip, attempted_at, scope) VALUES (?, ?, ?)",
            (ip, now.isoformat(), scope),
        )
    return True


def increment_playground_views(*, db_path: Path | None = None) -> int:
    """Atomically bump and return the playground page-view counter."""
    with _connect(db_path) as conn:
        row = conn.execute(
            "INSERT INTO playground_stats (key, value) VALUES ('views', 1) "
            "ON CONFLICT(key) DO UPDATE SET value = value + 1 "
            "RETURNING value",
        ).fetchone()
    return row[0] if row else 0


