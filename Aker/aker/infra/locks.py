"""File-lock primitives used to coordinate concurrent writers on shared
state inside a task directory.

The parallel design (dev/parallel.md §6.12) uses exactly two locks:

  - `.reservations.lock` — guards `_reservations.jsonl` append + the
    "max(N) + 1" allocation step. Held by slot processes and the main
    process briefly.
  - `.leaderboard.lock` — guards `leaderboard.jsonl` append + full
    rewrite of `leaderboard.md`. Held only by the main process.

Both are POSIX advisory fcntl locks. They are intra-machine only; that's
fine because `aker run` is single-machine by design (P13).
"""

from __future__ import annotations

import fcntl
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

RESERVATIONS_LOCK = ".reservations.lock"
LEADERBOARD_LOCK = ".leaderboard.lock"


@contextmanager
def file_lock(lock_path: Path | str) -> Iterator[None]:
    """Acquire an exclusive advisory fcntl lock on `lock_path`, blocking."""
    lock_path = Path(lock_path)
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    fd = open(lock_path, "a+")
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            fd.close()


@contextmanager
def reservations_lock(task_dir: Path | str) -> Iterator[None]:
    with file_lock(Path(task_dir) / RESERVATIONS_LOCK):
        yield


@contextmanager
def leaderboard_lock(task_dir: Path | str) -> Iterator[None]:
    with file_lock(Path(task_dir) / LEADERBOARD_LOCK):
        yield
