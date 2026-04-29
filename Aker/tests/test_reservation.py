"""Standalone smoke for `aker.reservation` + `aker.graph.scan_in_flight`.

Exercises:

- `open_reservation` allocates strictly increasing N, no reuse after
  close (P4).
- `committed` dir on disk is detected, so repeat-open gives next N.
- `sweep_stale` closes open reservations past timeout and moves
  staging dirs to `_orphans/`.
- `close_all_open(slot_id_filter=)` only closes matching slots.
- `scan_in_flight` returns reservations whose dir hasn't been committed,
  with meta peek fallback on JSON decode failures.

Run:

    python tests/test_reservation.py
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from aker.state import graph, reservation as res  # noqa: E402


def _make_task(td: Path) -> None:
    (td / "nodes").mkdir()


def _commit(td: Path, n: int, tag: str) -> Path:
    """Simulate a worker doing staging-rename."""
    staging = td / "nodes" / f".v{n}_{tag}.tmp"
    staging.mkdir()
    (staging / "meta.json").write_text(
        json.dumps(
            {
                "node_id": f"v{n}_{tag}",
                "parents": [],
                "action": "mutate" if n > 0 else "bootstrap",
                "direction": "test",
                "techniques": [],
                "attempt_status": "OK",
            }
        )
    )
    final = td / "nodes" / f"v{n}_{tag}"
    os.rename(staging, final)
    return final


def test_allocation_monotonic() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r1 = res.open_reservation(td, slot_id="s0")
        r2 = res.open_reservation(td, slot_id="s1")
        r3 = res.open_reservation(td, slot_id="s2")
        assert r1.reserved_n == 0
        assert r2.reserved_n == 1
        assert r3.reserved_n == 2
        # Close r1 — its N is NOT reused.
        res.close_reservation(td, r1.reservation_id, status=res.CLOSE_COMMITTED)
        r4 = res.open_reservation(td, slot_id="s3")
        assert r4.reserved_n == 3, f"expected 3, got {r4.reserved_n}"
        print("[alloc] OK monotonic + no reuse")


def test_close_reservation_is_idempotent() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r = res.open_reservation(td, slot_id="s0")
        res.close_reservation(td, r.reservation_id, status=res.CLOSE_COMMITTED)
        res.close_reservation(td, r.reservation_id, status=res.CLOSE_CRASHED, reason="late")
        events = [
            e for e in res.read_events(td)
            if e.get("event") == "close" and e.get("reservation_id") == r.reservation_id
        ]
        assert len(events) == 1, events
        assert events[0]["status"] == res.CLOSE_COMMITTED
        print("[close] OK duplicate close ignored")


def test_committed_on_disk_respected() -> None:
    # Fresh task dir with pre-existing committed nodes but empty jsonl.
    # N allocation should jump past the highest on-disk N.
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        _commit(td, 0, "foo")
        _commit(td, 7, "bar")
        r = res.open_reservation(td, slot_id="s0")
        assert r.reserved_n == 8, f"expected 8 (max_disk=7 + 1), got {r.reserved_n}"
        print("[disk ] OK on-disk max respected")


def test_sweep_stale() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r1 = res.open_reservation(td, slot_id="s0")
        # Create staging dir for r1 with partial meta.
        staging = td / "nodes" / f".v{r1.reserved_n}_partial.tmp"
        staging.mkdir()
        (staging / "kernel.cu").write_text("// partial\n")
        # Sweep with 0 timeout → r1 becomes stale.
        swept = res.sweep_stale(td, reservation_timeout_sec=0.0)
        assert len(swept) == 1, f"expected 1 swept, got {len(swept)}"
        assert swept[0].reservation_id == r1.reservation_id
        # Orphan relocation happened.
        orphans = list((td / "_orphans").iterdir()) if (td / "_orphans").is_dir() else []
        assert orphans, "expected orphan dir under _orphans/"
        assert any(f".v{r1.reserved_n}_partial.tmp" in p.name for p in orphans)
        assert not staging.exists(), "staging should have been moved"
        # Event log shows close=crashed.
        events = res.read_events(td)
        close_events = [e for e in events if e.get("event") == "close"]
        assert any(e.get("status") == res.CLOSE_CRASHED for e in close_events)
        print("[sweep] OK stale closed + orphan moved")


def test_close_all_open_slot_filter() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r_a = res.open_reservation(td, slot_id="sA")
        r_b = res.open_reservation(td, slot_id="sB")
        closed = res.close_all_open(
            td, status=res.CLOSE_CRASHED, reason="slot_crashed", slot_id_filter="sA"
        )
        assert len(closed) == 1
        assert closed[0].reservation_id == r_a.reservation_id
        # sB should still be open.
        still_open = res.open_reservations(td)
        assert len(still_open) == 1
        assert still_open[0].reservation_id == r_b.reservation_id
        print("[filter] OK slot_id_filter narrows close_all_open")


def test_scan_in_flight_with_meta_and_without() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r1 = res.open_reservation(td, slot_id="s0")
        r2 = res.open_reservation(td, slot_id="s1")
        # r1 gets a staging dir with parseable meta; r2 has none.
        staging = td / "nodes" / f".v{r1.reserved_n}_foo.tmp"
        staging.mkdir()
        (staging / "meta.json").write_text(
            json.dumps(
                {
                    "node_id": f"v{r1.reserved_n}_foo",
                    "parents": ["v0_naive_cuda"],
                    "direction": "some idea",
                }
            )
        )
        # Also drop a broken JSON into r2's staging to exercise the fallback.
        staging2 = td / "nodes" / f".v{r2.reserved_n}_bar.tmp"
        staging2.mkdir()
        (staging2 / "meta.json").write_text("{not valid json")

        inflight = graph.scan_in_flight(td)
        by_n = {rec.reserved_n: rec for rec in inflight}
        assert r1.reserved_n in by_n
        assert by_n[r1.reserved_n].staging_meta is not None
        assert by_n[r1.reserved_n].staging_meta["direction"] == "some idea"
        assert r2.reserved_n in by_n
        assert by_n[r2.reserved_n].staging_meta is None, "broken JSON → fallback"
        print("[peek ] OK meta peek + JSON-decode fallback")


def _pool_open_and_return_n(args: tuple[str, str]) -> int:
    """Module-level entry for the concurrent-allocation spawn pool."""
    task_dir_str, slot_id = args
    # Re-import under `spawn` — top-level sys.path insertion reruns.
    from aker.state.reservation import open_reservation as _open
    return _open(task_dir_str, slot_id=slot_id).reserved_n


def test_concurrent_allocation() -> None:
    """10 spawned processes concurrently open reservations; every N
    must be unique and contiguous. This stresses `reservations_lock`
    under real OS-level contention."""
    import multiprocessing as mp
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        ctx = mp.get_context("spawn")
        with ctx.Pool(processes=4) as pool:
            args = [(str(td), f"s{i}") for i in range(10)]
            ns = pool.map(_pool_open_and_return_n, args)
        assert len(ns) == 10
        assert len(set(ns)) == 10, f"duplicate Ns: {sorted(ns)}"
        assert set(ns) == set(range(10)), f"expected {{0..9}}, got {sorted(ns)}"
        print("[concur] OK 10 parallel opens yielded {0..9}")


def _age_open_event(td: Path, reservation_id: str) -> None:
    """Rewrite an open event's start_ts to year-2020 so sweep_stale
    treats it as timed out at any non-trivial threshold."""
    path = td / res.RESERVATIONS_FILE
    ancient_iso = "2020-01-01T00:00:00+00:00"
    new_lines: list[str] = []
    for ln in path.read_text().splitlines():
        try:
            evt = json.loads(ln)
        except json.JSONDecodeError:
            new_lines.append(ln)
            continue
        if (
            evt.get("event") == "open"
            and evt.get("reservation_id") == reservation_id
        ):
            evt["start_ts"] = ancient_iso
        new_lines.append(json.dumps(evt))
    path.write_text("\n".join(new_lines) + "\n")


def test_sweep_stale_backfill_committed() -> None:
    """open + committed dir on disk + timed out → close as committed,
    NOT reported in the swept list."""
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r = res.open_reservation(td, slot_id="s0")
        _commit(td, r.reserved_n, "backfill_me")
        _age_open_event(td, r.reservation_id)
        swept = res.sweep_stale(td, reservation_timeout_sec=0.5)
        assert swept == [], f"backfill should not appear in swept; got {swept}"
        by_id = res.reconstruct(res.read_events(td))
        assert by_id[r.reservation_id].status == res.CLOSE_COMMITTED
        print("[bkfill] OK sweep_stale backfills committed")


def test_sweep_stale_within_timeout_noop() -> None:
    """open + young reservation + huge timeout → nothing swept."""
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r = res.open_reservation(td, slot_id="s0")
        swept = res.sweep_stale(td, reservation_timeout_sec=3600.0)
        assert swept == []
        by_id = res.reconstruct(res.read_events(td))
        assert by_id[r.reservation_id].is_open
        print("[young ] OK within-timeout sweep is a no-op")


def test_close_all_open_backfill_committed() -> None:
    """close_all_open must NOT mislabel a reservation as crashed when a
    committed dir exists for its N — backfill as committed instead."""
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r = res.open_reservation(td, slot_id="s0")
        _commit(td, r.reserved_n, "real_node")
        closed = res.close_all_open(td, status=res.CLOSE_CRASHED, reason="x")
        # Backfill path is silent in the return list.
        assert closed == [], f"unexpectedly closed as crashed: {closed}"
        by_id = res.reconstruct(res.read_events(td))
        assert by_id[r.reservation_id].status == res.CLOSE_COMMITTED
        print("[bkfill2] OK close_all_open backfills committed")


def test_committed_dir_hides_from_inflight() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        _make_task(td)
        r1 = res.open_reservation(td, slot_id="s0")
        # Simulate completed work: committed dir exists, close event not yet
        # written (imagine slot crashed between rename and close-event).
        _commit(td, r1.reserved_n, "ok")
        inflight = graph.scan_in_flight(td)
        assert all(rec.reserved_n != r1.reserved_n for rec in inflight), (
            f"committed dir should hide from in-flight; got {[r.reserved_n for r in inflight]}"
        )
        print("[hide ] OK committed dir hides from in-flight")


def main() -> int:
    test_allocation_monotonic()
    test_close_reservation_is_idempotent()
    test_committed_on_disk_respected()
    test_concurrent_allocation()
    test_sweep_stale()
    test_sweep_stale_backfill_committed()
    test_sweep_stale_within_timeout_noop()
    test_close_all_open_slot_filter()
    test_close_all_open_backfill_committed()
    test_scan_in_flight_with_meta_and_without()
    test_committed_dir_hides_from_inflight()
    print("all reservation tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
