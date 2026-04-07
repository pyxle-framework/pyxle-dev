#!/usr/bin/env python3
"""Remove stale rows from the ``rate_limits`` table.

The ``rate_limits`` table tracks every rate-limited action call (one row
per call). ``db.check_rate_limit`` already deletes rows older than the
rolling window on every call, but only for IPs that are actively being
checked -- rows belonging to an IP that hit the site once and never came
back stay in the table forever, bloating the SQLite file on a long-lived
production host.

This script is meant to run out-of-band on a cron schedule (every 6
hours is enough; see ``DEPLOYMENT.md``). It takes the same 1-hour
window as ``check_rate_limit`` and issues a single ``DELETE`` for every
row older than ``now - 1 hour``.

Usage:

    python scripts/cleanup_rate_limits.py          # delete stale rows
    python scripts/cleanup_rate_limits.py --dry-run # only report counts

Exit codes:
    0 -- success (0 or more rows deleted)
    1 -- database file missing
    2 -- table missing (nothing to do, not an error on a fresh install)
    3 -- unexpected database error
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Default DB path: ``<repo root>/data/pyxle.db`` (matches ``db.py``).
_SCRIPT_DIR = Path(__file__).resolve().parent
_DEFAULT_DB_PATH = _SCRIPT_DIR.parent / "data" / "pyxle.db"

# Keep this identical to the default window in ``db.check_rate_limit``
# so entries that would no longer count towards any user's quota are
# the ones that get removed.
_WINDOW_SECONDS = 3600


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Delete stale rate_limits rows older than one hour.",
    )
    parser.add_argument(
        "--db",
        type=Path,
        default=_DEFAULT_DB_PATH,
        help=f"Path to the SQLite database (default: {_DEFAULT_DB_PATH}).",
    )
    parser.add_argument(
        "--window-seconds",
        type=int,
        default=_WINDOW_SECONDS,
        help=(
            "Rate-limit window in seconds. Rows older than "
            "now - window_seconds are deleted (default: 3600)."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report the counts without deleting anything.",
    )
    return parser.parse_args(argv)


def cleanup(db_path: Path, *, window_seconds: int, dry_run: bool) -> int:
    """Delete stale rows and return the exit code.

    Prints a concise summary to stdout for cron log inspection.
    """

    if not db_path.is_file():
        print(f"[cleanup_rate_limits] database not found: {db_path}", file=sys.stderr)
        return 1

    cutoff = datetime.now(tz=timezone.utc) - timedelta(seconds=window_seconds)
    cutoff_iso = cutoff.isoformat()

    try:
        conn = sqlite3.connect(str(db_path))
        try:
            # If the table does not exist yet (fresh install, no action has
            # been invoked), there is nothing to clean. Exit cleanly so the
            # cron job does not alarm on a benign condition.
            row = conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='rate_limits'"
            ).fetchone()
            if row is None:
                print(
                    "[cleanup_rate_limits] rate_limits table does not exist; "
                    "nothing to do"
                )
                return 2

            total_before = conn.execute(
                "SELECT COUNT(*) FROM rate_limits"
            ).fetchone()[0]
            stale_count = conn.execute(
                "SELECT COUNT(*) FROM rate_limits WHERE attempted_at < ?",
                (cutoff_iso,),
            ).fetchone()[0]

            if dry_run:
                print(
                    f"[cleanup_rate_limits] dry run: "
                    f"{stale_count} stale row(s) out of {total_before} total "
                    f"(cutoff={cutoff_iso}). No rows deleted."
                )
                return 0

            conn.execute(
                "DELETE FROM rate_limits WHERE attempted_at < ?",
                (cutoff_iso,),
            )
            conn.commit()

            total_after = conn.execute(
                "SELECT COUNT(*) FROM rate_limits"
            ).fetchone()[0]
            deleted = total_before - total_after

            print(
                f"[cleanup_rate_limits] deleted {deleted} stale row(s); "
                f"{total_after} fresh row(s) remain (cutoff={cutoff_iso})"
            )
            return 0
        finally:
            conn.close()
    except sqlite3.Error as exc:
        print(f"[cleanup_rate_limits] sqlite error: {exc}", file=sys.stderr)
        return 3


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    return cleanup(
        args.db,
        window_seconds=args.window_seconds,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    raise SystemExit(main())
