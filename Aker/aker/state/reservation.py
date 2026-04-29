"""Reservations — Python-side allocation and lifecycle of node version
numbers for the parallel iterate phase.

Each round opens a reservation, which reserves an integer `N`. The
worker later creates `nodes/v<N>_<tag>/` under that N. When the round
finishes, close is appended with one of the status values in
`CloseStatus`. N is never reused (P4), even on crash.

State is a flat append-only JSONL at `task_dir/_reservations.jsonl`.
"Current state" of any reservation is derived by walking the file
(open / close events, keyed by `reservation_id`). This keeps the writer
simple — no state-machine mutation, no fsck.

See dev/parallel.md §6.3, §6.10, §6.11, §6.12.3.
"""

from __future__ import annotations

import json
import logging
import os
import re
import shutil
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from aker.infra.locks import reservations_lock

log = logging.getLogger(__name__)

RESERVATIONS_FILE = "_reservations.jsonl"
ORPHANS_DIR = "_orphans"

# Close status enum. Reference: dev/parallel.md §6.3.
CLOSE_COMMITTED = "committed"        # audit passed; node on disk
CLOSE_AUDIT_FAILED = "audit_failed"  # review PASS but §6.10 A1-A9 violated
CLOSE_BAILED = "bailed_no_node"      # LLM gave up, no node written
CLOSE_CRASHED = "crashed"            # slot / broker / aker-run died mid-round


@dataclass
class Reservation:
    """A reservation, as reconstructed from the jsonl event log."""

    reservation_id: str
    reserved_n: int
    slot_id: str
    pid: int | None
    start_ts: float
    end_ts: float | None = None
    status: str | None = None            # None == still open
    reason: str | None = None            # for crashed/failed close

    @property
    def is_open(self) -> bool:
        return self.status is None

    def node_dir_name_prefix(self) -> str:
        return f"v{self.reserved_n}_"


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _now_ts() -> float:
    return time.time()


def _parse_ts(v) -> float | None:
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    try:
        return datetime.fromisoformat(str(v)).timestamp()
    except ValueError:
        return None


def read_events(task_dir: Path | str) -> list[dict]:
    """Read all events from `_reservations.jsonl`, tolerating partial tail."""
    path = Path(task_dir) / RESERVATIONS_FILE
    if not path.is_file():
        return []
    events: list[dict] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            # Partial tail line (writer in flight) — ignore silently.
            continue
    return events


def reconstruct(events: Iterable[dict]) -> dict[str, Reservation]:
    """Reconstruct one Reservation per reservation_id from the event log."""
    by_id: dict[str, Reservation] = {}
    for e in events:
        rid = e.get("reservation_id")
        if not rid:
            continue
        etype = e.get("event")
        if etype == "open":
            by_id[rid] = Reservation(
                reservation_id=rid,
                reserved_n=int(e["reserved_n"]),
                slot_id=str(e.get("slot_id", "?")),
                pid=e.get("pid"),
                start_ts=_parse_ts(e.get("start_ts")) or _now_ts(),
            )
        elif etype == "close":
            rec = by_id.get(rid)
            if rec is None:
                # close without open — synthesize a stub
                rec = Reservation(
                    reservation_id=rid,
                    reserved_n=int(e.get("reserved_n", -1)),
                    slot_id=str(e.get("slot_id", "?")),
                    pid=e.get("pid"),
                    start_ts=_parse_ts(e.get("start_ts")) or _now_ts(),
                )
                by_id[rid] = rec
            rec.status = str(e.get("status", CLOSE_CRASHED))
            rec.reason = e.get("reason")
            rec.end_ts = _parse_ts(e.get("end_ts")) or _now_ts()
    return by_id


def all_reserved_ns(task_dir: Path | str) -> set[int]:
    """Every N that has ever appeared in an open event — retire-all semantics (P4)."""
    events = read_events(task_dir)
    ns: set[int] = set()
    for e in events:
        if e.get("event") == "open" and "reserved_n" in e:
            try:
                ns.add(int(e["reserved_n"]))
            except (TypeError, ValueError):
                continue
    return ns


def max_committed_n_on_disk(task_dir: Path | str) -> int:
    """Max N visible in `nodes/v<N>_*/` — used to align reservations with
    a task whose reservations.jsonl was lost / never existed (old tasks)."""
    nodes_dir = Path(task_dir) / "nodes"
    if not nodes_dir.is_dir():
        return -1
    import re
    rx = re.compile(r"^v(\d+)_")
    best = -1
    for child in nodes_dir.iterdir():
        if not child.is_dir():
            continue
        m = rx.match(child.name)
        if m:
            best = max(best, int(m.group(1)))
    return best


def _append_event(task_dir: Path, event: dict) -> None:
    path = task_dir / RESERVATIONS_FILE
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(event) + "\n")


def open_reservation(
    task_dir: Path | str,
    *,
    slot_id: str,
    pid: int | None = None,
) -> Reservation:
    """Allocate a fresh N and append an `open` event. Holds the
    reservations lock only long enough to read-max-and-write."""
    task_dir = Path(task_dir).resolve()
    task_dir.mkdir(parents=True, exist_ok=True)
    reservation_id = f"r-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8]}"
    with reservations_lock(task_dir):
        used = all_reserved_ns(task_dir)
        on_disk_max = max_committed_n_on_disk(task_dir)
        next_n = max([on_disk_max] + list(used), default=-1) + 1
        event = {
            "event": "open",
            "reservation_id": reservation_id,
            "reserved_n": next_n,
            "slot_id": slot_id,
            "pid": pid if pid is not None else os.getpid(),
            "start_ts": _iso_now(),
        }
        _append_event(task_dir, event)
    return Reservation(
        reservation_id=reservation_id,
        reserved_n=next_n,
        slot_id=slot_id,
        pid=event["pid"],
        start_ts=_now_ts(),
    )


def close_reservation(
    task_dir: Path | str,
    reservation_id: str,
    *,
    status: str,
    reason: str | None = None,
) -> None:
    """Append a close event. Idempotent at the file-format level:
    appending twice is harmless (reconstruct keeps the last)."""
    task_dir = Path(task_dir).resolve()
    event: dict = {
        "event": "close",
        "reservation_id": reservation_id,
        "status": status,
        "end_ts": _iso_now(),
    }
    if reason:
        event["reason"] = reason
    with reservations_lock(task_dir):
        _append_event(task_dir, event)


def open_reservations(task_dir: Path | str) -> list[Reservation]:
    """All currently-open reservations, ordered by start_ts."""
    with reservations_lock(task_dir):
        events = read_events(task_dir)
    by_id = reconstruct(events)
    return sorted(
        [r for r in by_id.values() if r.is_open], key=lambda r: r.start_ts
    )


def sweep_stale(
    task_dir: Path | str,
    *,
    reservation_timeout_sec: float = 3600.0,
    orphan_prefix_on_close: bool = True,
) -> list[Reservation]:
    """Find reservations that are open for > timeout without a matching
    committed node on disk; close them as `crashed` and relocate any
    `.v<N>_*.tmp/` staging directories to `_orphans/`.

    Must be called by the main process, not by slots.
    """
    task_dir = Path(task_dir).resolve()
    now = _now_ts()
    with reservations_lock(task_dir):
        events = read_events(task_dir)
        by_id = reconstruct(events)
        to_close: list[Reservation] = []
        for r in by_id.values():
            if not r.is_open:
                continue
            if (now - r.start_ts) < reservation_timeout_sec:
                continue
            # Did a committed dir actually appear for this N?
            committed = _committed_dir_for(task_dir, r.reserved_n)
            if committed is not None:
                # Worker finished rename before dying — backfill close.
                _append_event(
                    task_dir,
                    {
                        "event": "close",
                        "reservation_id": r.reservation_id,
                        "status": CLOSE_COMMITTED,
                        "reason": "backfilled_from_disk",
                        "end_ts": _iso_now(),
                    },
                )
                r.status = CLOSE_COMMITTED
                continue
            _append_event(
                task_dir,
                {
                    "event": "close",
                    "reservation_id": r.reservation_id,
                    "status": CLOSE_CRASHED,
                    "reason": "stale_sweep",
                    "end_ts": _iso_now(),
                },
            )
            r.status = CLOSE_CRASHED
            r.reason = "stale_sweep"
            to_close.append(r)
        if orphan_prefix_on_close and to_close:
            _relocate_orphans(task_dir, [r.reserved_n for r in to_close])
    return to_close


def close_all_open(
    task_dir: Path | str,
    *,
    status: str = CLOSE_CRASHED,
    reason: str = "aker_run_exit",
    slot_id_filter: str | None = None,
) -> list[Reservation]:
    """Close every still-open reservation. Used by main-process atexit
    and by the Pool per-worker death hook (filter on slot_id).

    Returns the list that was closed this call.
    """
    task_dir = Path(task_dir).resolve()
    closed: list[Reservation] = []
    with reservations_lock(task_dir):
        events = read_events(task_dir)
        by_id = reconstruct(events)
        for r in by_id.values():
            if not r.is_open:
                continue
            if slot_id_filter is not None and r.slot_id != slot_id_filter:
                continue
            # If a committed dir exists, don't mislabel — backfill as committed.
            committed = _committed_dir_for(task_dir, r.reserved_n)
            if committed is not None:
                _append_event(
                    task_dir,
                    {
                        "event": "close",
                        "reservation_id": r.reservation_id,
                        "status": CLOSE_COMMITTED,
                        "reason": "backfilled_from_disk",
                        "end_ts": _iso_now(),
                    },
                )
                r.status = CLOSE_COMMITTED
                continue
            _append_event(
                task_dir,
                {
                    "event": "close",
                    "reservation_id": r.reservation_id,
                    "status": status,
                    "reason": reason,
                    "end_ts": _iso_now(),
                },
            )
            r.status = status
            r.reason = reason
            closed.append(r)
    return closed


def _committed_dir_for(task_dir: Path, n: int) -> Path | None:
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return None
    prefix = f"v{n}_"
    for child in nodes_dir.iterdir():
        if not child.is_dir():
            continue
        if child.name.startswith(prefix) and not child.name.startswith(".") and not child.name.endswith(".tmp"):
            return child
    return None


_DOT_VN_RE = re.compile(r"^\.v(\d+)_")


def _relocate_orphans(task_dir: Path, ns: list[int]) -> None:
    """Move any `nodes/.v<N>_*/` directory (ANY suffix — `.tmp`,
    `.peer_backup`, anything) for the given Ns into `_orphans/`.

    Previous version only matched `.tmp` — but LLMs have been observed
    inventing alternate suffixes (e.g. `.peer_backup`) as part of
    creative "fix" attempts. We now match any dot-prefix `.v<N>_*` dir
    and let the sweep rule decide by N.
    """
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return
    ns_set = set(ns)
    for child in list(nodes_dir.iterdir()):
        if not child.is_dir():
            continue
        m = _DOT_VN_RE.match(child.name)
        if not m:
            continue
        n = int(m.group(1))
        if n not in ns_set:
            continue
        _move_to_orphans(task_dir, child)


def sweep_nonstandard_staging(task_dir: Path | str) -> list[str]:
    """Scan `nodes/` for any dot-prefix `.v<N>_*` directory and evict
    the ones that don't correspond to a legitimate in-flight staging.

    A legitimate staging is `.v<N>_<tag>.tmp/` where `N` belongs to a
    CURRENTLY-open reservation. Anything else — stale `.tmp` from a
    crashed slot whose reservation already closed, LLM-invented
    suffixes like `.peer_backup`, dirs for closed Ns — gets moved to
    `_orphans/`.

    Intended to be called by `iterate.run` at startup, before spawning
    any worker slot. Must not run concurrently with active workers.
    Returns the list of relocated names for logging.
    """
    task_dir = Path(task_dir).resolve()
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return []

    # Under reservations_lock so we see a consistent snapshot of who is
    # currently open — though we're expected to run at startup when no
    # slots exist, this is cheap insurance.
    with reservations_lock(task_dir):
        events = read_events(task_dir)
        by_id = reconstruct(events)
        open_ns = {r.reserved_n for r in by_id.values() if r.is_open}

        relocated: list[str] = []
        for child in list(nodes_dir.iterdir()):
            if not child.is_dir():
                continue
            m = _DOT_VN_RE.match(child.name)
            if not m:
                continue
            n = int(m.group(1))
            # Legitimate iff: the dir is `.v<N>_<tag>.tmp/` AND N has
            # an open reservation.
            is_std_tmp = child.name.endswith(".tmp")
            if is_std_tmp and n in open_ns:
                continue
            _move_to_orphans(task_dir, child)
            relocated.append(child.name)
    return relocated


def _move_to_orphans(task_dir: Path, child: Path) -> None:
    orphans = task_dir / ORPHANS_DIR
    orphans.mkdir(exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    dest = orphans / f"{ts}_{child.name}"
    try:
        shutil.move(str(child), str(dest))
        log.info("relocated orphan %s → %s", child, dest)
    except OSError:
        log.exception("failed to relocate %s", child)
