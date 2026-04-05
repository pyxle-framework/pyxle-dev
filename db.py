"""Newsletter subscription storage.

Uses SQLite for local/simple hosting.  To switch databases later, replace
the ``SubscriptionStore`` implementation — the rest of the app talks only
to the public interface (``add_subscriber``, ``subscriber_exists``,
``subscriber_count``).
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
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


def increment_playground_views(*, db_path: Path | None = None) -> int:
    """Atomically bump and return the playground page-view counter."""
    with _connect(db_path) as conn:
        row = conn.execute(
            "INSERT INTO playground_stats (key, value) VALUES ('views', 1) "
            "ON CONFLICT(key) DO UPDATE SET value = value + 1 "
            "RETURNING value",
        ).fetchone()
    return row[0] if row else 0
