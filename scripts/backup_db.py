"""Daily SQLite backup with automatic pruning of old files.

Creates a timestamped backup of ``data/pyxle.db`` using SQLite's online
backup API (``Connection.backup`` — consistent even while the writer is
active, unlike a raw ``cp`` during a WAL checkpoint).  Old backups are
pruned automatically so the directory stays bounded.

Run
---
    python scripts/backup_db.py                 # default: keep 15 days
    python scripts/backup_db.py --keep-days 30  # custom retention
    python scripts/backup_db.py --dry-run       # report what would happen

Intended to be invoked by cron every 24h.

Exit codes
----------
    0  success (backup written, old files pruned)
    1  source database missing
    2  SQLite / I/O error during backup
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path


_DEFAULT_SOURCE = Path(__file__).resolve().parent.parent / "data" / "pyxle.db"
_DEFAULT_BACKUP_DIR = Path(__file__).resolve().parent.parent / "data" / "backups"
_DEFAULT_KEEP_DAYS = 15


def backup_database(source: Path, destination: Path) -> None:
    """Atomically snapshot *source* into *destination* using SQLite's backup API.

    This is the only safe way to copy a live SQLite database — a naive
    ``cp`` can capture the file mid-write and produce a corrupt copy.
    """
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Connect to the source read-only so we never hold a write lock.
    src_uri = f"file:{source}?mode=ro"
    with sqlite3.connect(src_uri, uri=True) as src, sqlite3.connect(destination) as dst:
        src.backup(dst)


def prune_old_backups(backup_dir: Path, keep_days: int, *, dry_run: bool = False) -> list[Path]:
    """Delete ``pyxle-*.db`` files older than *keep_days* days.

    Returns the list of files that were (or would be, with --dry-run) removed.
    """
    if not backup_dir.exists():
        return []

    cutoff = datetime.now(tz=timezone.utc) - timedelta(days=keep_days)
    removed: list[Path] = []
    for candidate in sorted(backup_dir.glob("pyxle-*.db")):
        try:
            mtime = datetime.fromtimestamp(candidate.stat().st_mtime, tz=timezone.utc)
        except OSError:
            continue
        if mtime < cutoff:
            if not dry_run:
                candidate.unlink(missing_ok=True)
            removed.append(candidate)
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--source", type=Path, default=_DEFAULT_SOURCE,
                        help="SQLite file to back up (default: data/pyxle.db)")
    parser.add_argument("--dest-dir", type=Path, default=_DEFAULT_BACKUP_DIR,
                        help="Directory to write timestamped backups into")
    parser.add_argument("--keep-days", type=int, default=_DEFAULT_KEEP_DAYS,
                        help=f"Retention in days (default: {_DEFAULT_KEEP_DAYS})")
    parser.add_argument("--dry-run", action="store_true",
                        help="Report without writing or deleting anything")
    args = parser.parse_args()

    if not args.source.exists():
        print(f"ERROR: source database not found: {args.source}", file=sys.stderr)
        return 1

    stamp = datetime.now(tz=timezone.utc).strftime("%Y%m%d")
    destination = args.dest_dir / f"pyxle-{stamp}.db"

    if args.dry_run:
        print(f"[dry-run] would backup {args.source} -> {destination}")
    else:
        try:
            backup_database(args.source, destination)
        except (sqlite3.Error, OSError) as exc:
            print(f"ERROR: backup failed: {exc}", file=sys.stderr)
            return 2
        size_kb = destination.stat().st_size // 1024
        print(f"backup ok: {destination} ({size_kb} KB)")

    removed = prune_old_backups(args.dest_dir, args.keep_days, dry_run=args.dry_run)
    if removed:
        prefix = "[dry-run] would remove" if args.dry_run else "pruned"
        for path in removed:
            print(f"{prefix}: {path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
