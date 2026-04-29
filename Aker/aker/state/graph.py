"""Graph state helpers for the iterate phase.

Python owns the graph structure: it scans `nodes/` and `leaderboard.jsonl`
on disk, assembles a human-readable summary, and hands that summary to the
iterate worker. The LLM does not maintain the graph itself — it only
proposes new nodes by writing files, which Python then re-scans next round.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

_NODE_ID_RE = re.compile(r"^v(\d+)_[A-Za-z0-9_]+$")
_STAGING_RE = re.compile(r"^\.v(\d+)_([A-Za-z0-9_]+)\.tmp$")


@dataclass
class NodeRecord:
    """One node's on-disk state, joined across meta.json + leaderboard."""

    node_id: str
    version_index: int
    meta: dict
    leaderboard_row: dict | None  # None if the attempt failed or never tested
    profile_files: list[str] = field(default_factory=list)  # files under nodes/<id>/profile/


def _parse_version_index(node_id: str) -> int | None:
    m = _NODE_ID_RE.match(node_id)
    return int(m.group(1)) if m else None


def scan_nodes(task_dir: Path | str) -> list[NodeRecord]:
    """Return all nodes under `task_dir/nodes/`, ordered by version index.

    A node is any directory matching `v<N>_<tag>` that contains a
    `meta.json`. `leaderboard_row` is matched by `node_id`; it is `None`
    for nodes that have no row (failed attempts not recorded in the
    leaderboard).
    """
    task_dir = Path(task_dir).resolve()
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return []

    lb_rows = _read_leaderboard(task_dir)
    lb_by_id: dict[str, dict] = {row["node_id"]: row for row in lb_rows if "node_id" in row}

    records: list[NodeRecord] = []
    for child in sorted(nodes_dir.iterdir()):
        if not child.is_dir():
            continue
        idx = _parse_version_index(child.name)
        if idx is None:
            continue
        meta_path = child / "meta.json"
        if not meta_path.is_file():
            continue
        try:
            meta = json.loads(meta_path.read_text())
        except json.JSONDecodeError:
            continue
        records.append(
            NodeRecord(
                node_id=child.name,
                version_index=idx,
                meta=meta,
                leaderboard_row=lb_by_id.get(child.name),
                profile_files=_list_profile_files(child / "profile"),
            )
        )
    records.sort(key=lambda r: r.version_index)
    return records


def next_version_index(records: list[NodeRecord]) -> int:
    """Return the next `v<N>` integer to use (max existing + 1, or 0)."""
    return max((r.version_index for r in records), default=-1) + 1


def _list_profile_files(profile_dir: Path) -> list[str]:
    if not profile_dir.is_dir():
        return []
    return sorted(p.name for p in profile_dir.iterdir() if p.is_file())


def _read_leaderboard(task_dir: Path) -> list[dict]:
    lb_path = task_dir / "leaderboard.jsonl"
    if not lb_path.is_file():
        return []
    rows: list[dict] = []
    for line in lb_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


@dataclass
class InFlightRecord:
    """A peer worker's reservation that hasn't committed yet.

    Worker prompt treats these as **informational only** — they cannot be
    used as parents (dev/parallel.md §6.5, §6.10 A4). Meta may be absent
    if the peer hasn't written staging yet.
    """

    reserved_n: int
    slot_id: str
    started_iso: str
    staging_meta: dict | None  # None if no meta.json staged yet


def scan_in_flight(task_dir: Path | str) -> list[InFlightRecord]:
    """List peer reservations that are open and not yet committed.

    Consumes `_reservations.jsonl` via `aker.reservation`, then for each
    open reservation tries to peek `nodes/.v<N>_*.tmp/meta.json` for a
    direction hint. JSON decode failures silently fall back to `None`
    (the peer may be writing in-flight; no locks on reads — §6.12.2).
    """
    # Imported here to avoid a module-level cycle with aker.reservation,
    # which imports aker.locks (module-level fcntl is fine).
    from aker.state.reservation import open_reservations  # noqa: PLC0415

    task_dir = Path(task_dir).resolve()
    records: list[InFlightRecord] = []
    for r in open_reservations(task_dir):
        # Skip entries that already have a committed directory on disk —
        # they just haven't had their close event flushed yet.
        committed = _committed_dir_for(task_dir, r.reserved_n)
        if committed is not None:
            continue
        records.append(
            InFlightRecord(
                reserved_n=r.reserved_n,
                slot_id=r.slot_id,
                started_iso=_ts_iso(r.start_ts),
                staging_meta=_peek_staging_meta(task_dir, r.reserved_n),
            )
        )
    return records


def _committed_dir_for(task_dir: Path, n: int) -> Path | None:
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return None
    prefix = f"v{n}_"
    for child in nodes_dir.iterdir():
        if not child.is_dir():
            continue
        if child.name.startswith(prefix) and not child.name.startswith("."):
            return child
    return None


def _peek_staging_meta(task_dir: Path, n: int) -> dict | None:
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return None
    for child in nodes_dir.iterdir():
        if not child.is_dir():
            continue
        m = _STAGING_RE.match(child.name)
        if not m or int(m.group(1)) != n:
            continue
        meta_path = child / "meta.json"
        if not meta_path.is_file():
            return None
        try:
            return json.loads(meta_path.read_text())
        except (json.JSONDecodeError, OSError):
            # Peer is writing; tolerate and return None.
            return None
    return None


def _ts_iso(ts: float) -> str:
    try:
        return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%H:%M:%S UTC")
    except (OSError, OverflowError, ValueError):
        return "?"


def format_graph_summary(
    records: list[NodeRecord],
    in_flight: list[InFlightRecord] | None = None,
) -> str:
    """Render the graph state as markdown for the iterate worker.

    The summary has three parts:
      - a leaderboard table (only nodes with a successful acc+perf run)
      - a per-node detail block listing parents, direction, rationale,
        techniques, and attempt status — these are the "edges as ideas"
        the worker must read to avoid duplicating failed experiments.
      - if `in_flight` is non-empty, an "In-flight" section listing peer
        reservations that are still being written (informational only —
        the worker MUST NOT use these as parents; see §6.5 + A4).
    """
    if not records and not (in_flight or []):
        return "_(graph is empty — no nodes yet)_"

    lines: list[str] = []
    lines.append("## Leaderboard (sorted by runtime_ms_primary ASC; failed attempts excluded)")
    lines.append("")
    lines.append(
        "| node_id | parents | action | direction | primary_ms | gen_ms | acc | nan | inf |"
    )
    lines.append("|---|---|---|---|---|---|---|---|---|")
    ranked = sorted(
        [r for r in records if r.leaderboard_row],
        key=lambda r: _safe_runtime(r.leaderboard_row),
    )
    if not ranked:
        lines.append("| _(no successfully measured nodes yet)_ |||||||||")
    for r in ranked:
        row = r.leaderboard_row or {}
        lines.append(
            "| {nid} | {par} | {act} | {dirn} | {pms} | {gms} | {acc} | {nan} | {inf} |".format(
                nid=r.node_id,
                par=_fmt_parents(row.get("parents")),
                act=row.get("action", "-"),
                dirn=_short(row.get("direction"), 40),
                pms=_fmt_ms(row.get("runtime_ms_primary")),
                gms=_fmt_ms(row.get("runtime_ms_generalization")),
                acc=row.get("acc_status", "-"),
                nan=row.get("nan_count", "-"),
                inf=row.get("inf_count", "-"),
            )
        )
    lines.append("")

    lines.append("## Per-node detail (edges = ideas; read before proposing new work)")
    lines.append("")
    for r in records:
        m = r.meta
        parents = m.get("parents") or []
        parent_str = ", ".join(parents) if parents else "(none)"
        status = m.get("attempt_status", "OK" if r.leaderboard_row else "UNKNOWN")
        header = f"### {r.node_id} — action={m.get('action', '?')}, parents=[{parent_str}], status={status}"
        lines.append(header)
        if m.get("direction"):
            lines.append(f"- **direction**: {m['direction']}")
        techs = m.get("techniques") or []
        if techs:
            lines.append(f"- **techniques**: {', '.join(techs)}")
        if m.get("rationale"):
            lines.append(f"- **rationale**: {m['rationale']}")
        if status != "OK" and m.get("failure_reason"):
            lines.append(f"- **failure_reason**: {m['failure_reason']}")
        lines.append(
            f"- **full design notes**: `nodes/{r.node_id}/notes.md` "
            "(cat this if considering as a base)"
        )
        if r.profile_files:
            lines.append(
                f"- **profile artifacts**: `nodes/{r.node_id}/profile/` "
                f"({', '.join(r.profile_files)}) — diffable against other "
                "profiled nodes"
            )
        lines.append("")

    if in_flight:
        lines.append(
            "## In-flight (other workers are currently working on these — "
            "informational ONLY; do NOT list any of them as a parent)"
        )
        lines.append("")
        for f in sorted(in_flight, key=lambda x: x.reserved_n):
            meta = f.staging_meta or {}
            parents = meta.get("parents") or []
            direction = meta.get("direction")
            bits = [f"v{f.reserved_n}"]
            if parents:
                bits.append(f"parent(s): {', '.join(parents)}")
            if direction:
                bits.append(f"direction: {direction!r}")
            if not parents and not direction:
                bits.append("(no meta yet)")
            bits.append(f"slot {f.slot_id}, started {f.started_iso}")
            lines.append(f"- {' — '.join(bits)}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def _fmt_parents(parents) -> str:
    if not parents:
        return "-"
    if isinstance(parents, list):
        return ", ".join(str(p) for p in parents)
    return str(parents)


def _fmt_ms(v) -> str:
    if isinstance(v, (int, float)):
        return f"{v:.3f}"
    return "-"


def _short(v, n: int) -> str:
    if v is None:
        return "-"
    s = str(v)
    return s if len(s) <= n else s[: n - 1] + "…"


def _safe_runtime(row: dict | None) -> float:
    if not row:
        return float("inf")
    v = row.get("runtime_ms_primary")
    if isinstance(v, (int, float)) and v > 0:
        return float(v)
    return float("inf")


def backfill_notes_md(task_dir: Path | str) -> list[str]:
    """Write a minimal `notes.md` for any node that doesn't have one.

    Older nodes (from before notes.md was required) are backfilled from
    their `meta.json` so the iterate audit stops tripping on them.
    Returns the list of node_ids that were backfilled.
    """
    task_dir = Path(task_dir).resolve()
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return []
    backfilled: list[str] = []
    for rec in scan_nodes(task_dir):
        notes_path = nodes_dir / rec.node_id / "notes.md"
        if notes_path.is_file():
            continue
        notes_path.write_text(_synthesize_notes_from_meta(rec))
        backfilled.append(rec.node_id)
    return backfilled


def _synthesize_notes_from_meta(rec: NodeRecord) -> str:
    m = rec.meta
    lines = [f"# {rec.node_id} — design notes (auto-backfilled)", ""]
    lines.append(
        "> This `notes.md` was generated after the fact from `meta.json`. "
        "It is a placeholder — a future worker picking this node as a base "
        "should refer to `kernel.cu` directly for ground truth."
    )
    lines.append("")
    action = m.get("action") or "?"
    parents = m.get("parents") or []
    lines.append(f"- **action**: `{action}`")
    lines.append(f"- **parents**: {', '.join(parents) if parents else '(none — bootstrap node)'}")
    if m.get("direction"):
        lines.append(f"- **direction (delta from parent)**: {m['direction']}")
    techs = m.get("techniques") or []
    if techs:
        lines.append(f"- **techniques**: {', '.join(techs)}")
    lines.append("")
    if m.get("rationale"):
        lines.append("## Rationale (from meta.json)")
        lines.append("")
        lines.append(m["rationale"])
        lines.append("")
    lines.append("## Caveat")
    lines.append("")
    lines.append(
        "No hand-written design doc was captured at creation time. The "
        "core strategy, rejected alternatives, and invariants must be "
        "inferred from `kernel.cu` until a future worker refreshes this "
        "file."
    )
    lines.append("")
    return "\n".join(lines)


def patch_node_id_in_reports(node_dir: Path | str) -> bool:
    """Rewrite `node_id` in the node's report_*.json so it matches the
    directory name.

    Workers run `akerjob test_*` against the staging name (e.g.
    `.v18_foo.tmp`); the test scripts capture that staging id into the
    report files. After the worker renames `.v18_foo.tmp` → `v18_foo`,
    the reports' `node_id` field is stale. Reviewers correctly flag
    the mismatch as a non-blocking note.

    Idempotent: returns True only if anything was actually changed.
    Tolerant of missing files and parse errors — report-level audits
    will catch those separately.
    """
    node_dir = Path(node_dir)
    if not node_dir.is_dir():
        return False
    target_name = node_dir.name
    changed_any = False
    for fname in ("report_acc.json", "report_perf.json"):
        p = node_dir / fname
        if not p.is_file():
            continue
        try:
            data = json.loads(p.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(data, dict):
            continue
        if data.get("node_id") and data["node_id"] != target_name:
            data["node_id"] = target_name
            try:
                p.write_text(json.dumps(data, indent=2, ensure_ascii=False))
                changed_any = True
            except OSError:
                continue
    return changed_any


def backfill_report_node_ids(task_dir: Path | str) -> list[str]:
    """One-shot scan: ensure every committed node's report_*.json
    carries the correct `node_id`. Returns the list of node ids that
    were actually patched (so callers can log only when work happened)."""
    task_dir = Path(task_dir).resolve()
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return []
    fixed: list[str] = []
    for child in sorted(nodes_dir.iterdir()):
        if not child.is_dir() or child.name.startswith("."):
            continue
        if patch_node_id_in_reports(child):
            fixed.append(child.name)
    return fixed


def backfill_v0_meta(task_dir: Path | str) -> bool:
    """Ensure `nodes/v0_naive_cuda/meta.json` has the iterate-era fields.

    Earlier bootstrap versions wrote meta.json without `parents` /
    `action`; iterate needs those fields to exist. If the file is missing
    keys, they are added in place. Returns True if the file was modified.
    """
    task_dir = Path(task_dir).resolve()
    meta_path = task_dir / "nodes" / "v0_naive_cuda" / "meta.json"
    if not meta_path.is_file():
        return False
    try:
        meta = json.loads(meta_path.read_text())
    except json.JSONDecodeError:
        return False
    changed = False
    defaults = {
        "node_id": "v0_naive_cuda",
        "parents": [],
        "action": "bootstrap",
        "direction": None,
        "rationale": "simplest CUDA C implementation; first graph node",
        "techniques": ["cuda_naive"],
        "attempt_status": "OK",
    }
    for k, v in defaults.items():
        if k not in meta:
            meta[k] = v
            changed = True
    if changed:
        meta_path.write_text(json.dumps(meta, indent=2, ensure_ascii=False))
    return changed
