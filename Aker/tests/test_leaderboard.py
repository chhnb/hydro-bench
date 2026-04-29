"""Smoke for `aker.leaderboard` writer.

Exercises:

- `commit_row` assembles a row from meta.json + report_*.json and
  upserts it into leaderboard.jsonl.
- `leaderboard.md` is regenerated atomically, sorted ASC by
  runtime_ms_primary.
- `attempt_status=FAIL` nodes are skipped (no row appended).
- Malformed / missing reports raise LeaderboardError.

Run:

    python tests/test_leaderboard.py
"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from aker.state.leaderboard import LeaderboardError, commit_row, regenerate_md  # noqa: E402


def _make_node(td: Path, node_id: str, *, mean_ms: float, status: str = "OK") -> None:
    nd = td / "nodes" / node_id
    nd.mkdir(parents=True, exist_ok=True)
    (nd / "kernel.cu").write_text("// stub\n")
    (nd / "kernel.py").write_text("# stub\n")
    (nd / "notes.md").write_text("# stub notes\n\nsome content\n")
    meta = {
        "node_id": node_id,
        "parents": ["v0_naive_cuda"] if node_id != "v0_naive_cuda" else [],
        "action": "bootstrap" if node_id == "v0_naive_cuda" else "mutate",
        "direction": f"direction for {node_id}",
        "techniques": ["test"],
        "attempt_status": status,
    }
    if status == "FAIL":
        meta["failure_reason"] = "stub failure"
    (nd / "meta.json").write_text(json.dumps(meta))
    (nd / "report_acc.json").write_text(
        json.dumps(
            {
                "node_id": node_id,
                "summary": {"status": "OK", "total_nan_count": 0, "total_inf_count": 0},
                "observations": [],
            }
        )
    )
    (nd / "report_perf.json").write_text(
        json.dumps(
            {
                "node_id": node_id,
                "status": "OK",
                "measurements": [
                    {
                        "shape": "primary",
                        "mean_ms": mean_ms,
                        "std_ms": 0.01,
                        "warmup_iters": 10,
                        "timed_iters": 100,
                    }
                ],
            }
        )
    )


def test_commit_and_regen() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        (td / "nodes").mkdir()
        _make_node(td, "v0_naive_cuda", mean_ms=2.5)
        _make_node(td, "v1_foo", mean_ms=1.2)
        _make_node(td, "v2_bar", mean_ms=0.8)

        for nid in ("v0_naive_cuda", "v1_foo", "v2_bar"):
            commit_row(td, nid)

        jsonl = (td / "leaderboard.jsonl").read_text().splitlines()
        assert len(jsonl) == 3, f"expected 3 rows, got {len(jsonl)}"
        md = (td / "leaderboard.md").read_text()
        # md's data rows should be in fastest-first order. Extract node_id
        # from column 1 of each data row line.
        data_rows = [
            ln for ln in md.splitlines()
            if ln.startswith("| v") and "_" in ln
        ]
        ordered = [ln.split("|")[1].strip() for ln in data_rows]
        assert ordered == ["v2_bar", "v1_foo", "v0_naive_cuda"], ordered
        print("[commit ] OK 3 rows committed + md sorted")


def test_fail_node_is_skipped() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        (td / "nodes").mkdir()
        _make_node(td, "v0_naive_cuda", mean_ms=2.5, status="OK")
        _make_node(td, "v1_bad", mean_ms=0.0, status="FAIL")
        commit_row(td, "v0_naive_cuda")
        result = commit_row(td, "v1_bad")
        assert result.get("skipped"), f"FAIL node should be skipped, got {result}"
        jsonl = (td / "leaderboard.jsonl").read_text().splitlines()
        assert len(jsonl) == 1, f"FAIL node should not append; got {len(jsonl)} rows"
        print("[skip  ] OK FAIL node skipped")


def test_commit_is_idempotent_by_node_id() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        (td / "nodes").mkdir()
        _make_node(td, "v0_naive_cuda", mean_ms=2.5, status="OK")
        commit_row(td, "v0_naive_cuda")
        commit_row(td, "v0_naive_cuda")

        jsonl = (td / "leaderboard.jsonl").read_text().splitlines()
        assert len(jsonl) == 1, f"duplicate commit should upsert, got {len(jsonl)} rows"
        row = json.loads(jsonl[0])
        assert row["node_id"] == "v0_naive_cuda"
        print("[idem  ] OK repeated commit upserts by node_id")


def test_malformed_raises() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        (td / "nodes").mkdir()
        _make_node(td, "v0_bad", mean_ms=1.0)
        # corrupt report_perf
        (td / "nodes" / "v0_bad" / "report_perf.json").write_text("{broken")
        try:
            commit_row(td, "v0_bad")
        except LeaderboardError:
            print("[raise ] OK LeaderboardError for malformed report")
            return
        raise AssertionError("expected LeaderboardError")


def test_regenerate_md_alone() -> None:
    with tempfile.TemporaryDirectory() as td_str:
        td = Path(td_str)
        (td / "nodes").mkdir()
        # No rows yet — regenerate_md should still produce a valid md.
        regenerate_md(td)
        md = (td / "leaderboard.md").read_text()
        assert "Leaderboard" in md
        assert "0 successful node" in md
        print("[regen ] OK empty leaderboard regen produces valid md")


def main() -> int:
    test_commit_and_regen()
    test_fail_node_is_skipped()
    test_commit_is_idempotent_by_node_id()
    test_malformed_raises()
    test_regenerate_md_alone()
    print("all leaderboard tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
