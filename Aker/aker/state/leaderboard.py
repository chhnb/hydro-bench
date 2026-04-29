"""Leaderboard writer. Python owns `leaderboard.jsonl` and
`leaderboard.md` (dev/parallel.md §6.12.1).

After a reservation closes `committed` with `attempt_status=OK`, the
main process calls `commit_row(task_dir, node_id)` to:

1. Read the node's `meta.json` + `report_acc.json` + `report_perf.json`.
2. Assemble a leaderboard row with the existing schema.
3. Append the row to `leaderboard.jsonl`.
4. Rewrite `leaderboard.md` from the full jsonl, sorted by
   runtime_ms_primary ASC.

All under `.leaderboard.lock`. `leaderboard.md` regen reads every node's
meta.json (for direction / action), which is fine because committed
dirs are immutable — §6.12.2.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from aker.infra.locks import leaderboard_lock

log = logging.getLogger(__name__)

LEADERBOARD_JSONL = "leaderboard.jsonl"
LEADERBOARD_MD = "leaderboard.md"


class LeaderboardError(RuntimeError):
    pass


def commit_row(task_dir: Path | str, node_id: str) -> dict[str, Any]:
    """Build and persist the leaderboard row for `node_id`.

    Called by the main process after a reservation closes committed with
    `attempt_status=OK`. Does nothing (returns the assembled row without
    persisting) if the node is FAIL.

    Raises LeaderboardError if the node's artifacts are missing or
    malformed — the caller can treat this as audit failure.
    """
    task_dir = Path(task_dir).resolve()
    node_dir = task_dir / "nodes" / node_id
    if not node_dir.is_dir():
        raise LeaderboardError(f"node dir missing: {node_dir}")
    meta = _read_json(node_dir / "meta.json")
    if meta.get("attempt_status") != "OK":
        return {"skipped": True, "reason": f"attempt_status={meta.get('attempt_status')}"}

    acc = _read_json(node_dir / "report_acc.json")
    perf = _read_json(node_dir / "report_perf.json")
    row = _assemble_row(node_id, meta, acc, perf)

    with leaderboard_lock(task_dir):
        _append_jsonl(task_dir / LEADERBOARD_JSONL, row)
        _regenerate_md(task_dir)
    return row


def regenerate_md(task_dir: Path | str) -> None:
    """Rewrite `leaderboard.md` from the current jsonl. Useful at
    bootstrap time when there's no row to append but the .md should
    still exist."""
    task_dir = Path(task_dir).resolve()
    with leaderboard_lock(task_dir):
        _regenerate_md(task_dir)


def _assemble_row(node_id: str, meta: dict, acc: dict, perf: dict) -> dict[str, Any]:
    perf_status = perf.get("status")
    if perf_status != "OK":
        raise LeaderboardError(
            f"{node_id}: report_perf.json status={perf_status!r}, expected OK"
        )
    primary = _find_measurement(perf, "primary")
    if primary is None:
        raise LeaderboardError(f"{node_id}: no measurement for shape='primary'")
    mean_ms = primary.get("mean_ms")
    if not _is_pos_finite(mean_ms):
        raise LeaderboardError(
            f"{node_id}: primary.mean_ms not positive finite: {mean_ms!r}"
        )
    gen = _find_measurement(perf, "generalization")
    gen_ms = gen.get("mean_ms") if isinstance(gen, dict) else None

    acc_summary = acc.get("summary") or {}
    acc_status = acc_summary.get("status")
    if acc_status != "OK":
        raise LeaderboardError(
            f"{node_id}: report_acc.json summary.status={acc_status!r}, expected OK"
        )
    nan_count = int(acc_summary.get("total_nan_count") or 0)
    inf_count = int(acc_summary.get("total_inf_count") or 0)

    return {
        "node_id": node_id,
        "parents": list(meta.get("parents") or []),
        "action": meta.get("action") or "mutate",
        "direction": meta.get("direction"),
        "techniques": list(meta.get("techniques") or []),
        "runtime_ms_primary": float(mean_ms),
        "runtime_ms_generalization": float(gen_ms) if _is_pos_finite(gen_ms) else None,
        "acc_status": "OK",
        "nan_count": nan_count,
        "inf_count": inf_count,
        "created_at": meta.get("created_at") or datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }


def _find_measurement(perf: dict, shape: str) -> dict | None:
    for m in perf.get("measurements") or []:
        if isinstance(m, dict) and m.get("shape") == shape:
            return m
    return None


def _read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as e:
        raise LeaderboardError(f"cannot read {path}: {e}") from e


def _append_jsonl(path: Path, row: dict) -> None:
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")


def _regenerate_md(task_dir: Path) -> None:
    jsonl_path = task_dir / LEADERBOARD_JSONL
    md_path = task_dir / LEADERBOARD_MD
    rows = _read_all_rows(jsonl_path)
    rows.sort(key=lambda r: _sort_key(r))
    lines = [
        "# Leaderboard",
        "",
        f"_{len(rows)} successful node(s); sorted by runtime_ms_primary ASC._",
        "",
        "| node_id | parents | action | direction | primary_ms | gen_ms | acc | nan | inf |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        lines.append(
            "| {nid} | {par} | {act} | {dir} | {pms} | {gms} | {acc} | {nan} | {inf} |".format(
                nid=r.get("node_id", "?"),
                par=", ".join(r.get("parents") or []) or "-",
                act=r.get("action", "-"),
                dir=_short(r.get("direction"), 48),
                pms=_fmt_ms(r.get("runtime_ms_primary")),
                gms=_fmt_ms(r.get("runtime_ms_generalization")),
                acc=r.get("acc_status", "-"),
                nan=r.get("nan_count", "-"),
                inf=r.get("inf_count", "-"),
            )
        )
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _read_all_rows(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    rows: list[dict] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def _sort_key(row: dict) -> float:
    v = row.get("runtime_ms_primary")
    return float(v) if _is_pos_finite(v) else float("inf")


def _fmt_ms(v) -> str:
    if v is None:
        return "-"
    if isinstance(v, (int, float)) and _is_pos_finite(v):
        return f"{float(v):.3f}"
    return "-"


def _short(v, n: int) -> str:
    if v is None:
        return "-"
    s = str(v)
    return s if len(s) <= n else s[: n - 1] + "…"


def _is_pos_finite(v) -> bool:
    if not isinstance(v, (int, float)):
        return False
    if v != v:  # NaN
        return False
    if v in (float("inf"), float("-inf")):
        return False
    return v > 0
