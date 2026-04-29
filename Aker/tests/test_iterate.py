# -*- coding: utf-8 -*-
"""Harness: drive the iterate phase against a bootstrapped task.

Prerequisites: `tasks/<TASK_NAME>/` must already contain `spec.md`, the
shared test infra, `leaderboard.{jsonl,md}`, and at least one node
(typically `v0_naive_cuda`) — produced by the spec + bootstrap phases.
This script just wires the harness (logging, per-round pretty-print,
exit code) around a single `aker.iterate.run(task_dir, rounds=N)` call.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from aker.phases import iterate  # noqa: E402
from aker.phases.iterate import IterateReport, RoundReport  # noqa: E402

TASK_ROOT = ROOT / "tasks"
DEFAULT_TASK_NAME = "_try_fp8_nvfp4_cast"


def _format_round(rr: RoundReport) -> str:
    lines = [
        f"[round {rr.round_index}] slot={rr.slot_id} status={rr.status} "
        f"review={rr.review_status} attempts={rr.review_attempts} "
        f"reservation={rr.reservation_id} N={rr.reserved_n} "
        f"new_node={rr.new_node_id or '-'}"
    ]
    for e in rr.audit_errors:
        lines.append(f"    audit_error: {e}")
    return "\n".join(lines)


def _format_report(report: IterateReport) -> str:
    lines = [f"total rounds: {len(report.rounds)} (ok={report.num_ok})"]
    for rr in report.rounds:
        lines.append(_format_round(rr))
    if report.successful_nodes:
        lines.append(f"successful new nodes: {', '.join(report.successful_nodes)}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--task",
        default=DEFAULT_TASK_NAME,
        help=f"task directory name under tasks/ (default: {DEFAULT_TASK_NAME})",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="number of iterate rounds to run (default: 1)",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=5,
        help="max worker↔reviewer retries per round (default: 5)",
    )
    parser.add_argument(
        "--rng-seed",
        type=int,
        default=None,
        help="seed for the worker-session-lifespan RNG (default: random)",
    )
    parser.add_argument(
        "--parallel",
        type=int,
        default=1,
        help="concurrent slots (default: 1)",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )

    task_dir = TASK_ROOT / args.task
    if not (task_dir / "spec.md").exists():
        print(f"ERROR: {task_dir}/spec.md not found. Run tests/test_spec.py first.")
        return 1
    if not (task_dir / "nodes").is_dir():
        print(f"ERROR: {task_dir}/nodes/ not found. Run tests/test_bootstrap.py first.")
        return 1

    log_dir = task_dir / "_iterate_logs"
    print(f"task dir: {task_dir}")
    print(f"log dir:  {log_dir}")
    print(f"rounds:   {args.rounds}")
    print()

    report = iterate.run(
        task_dir,
        rounds=args.rounds,
        parallel=args.parallel,
        max_retries=args.max_retries,
        rng_seed=args.rng_seed,
    )

    print(_format_report(report))
    print(f"\nper-round transcripts under: {log_dir}")

    return 0 if report.num_ok == len(report.rounds) and report.rounds else 2


if __name__ == "__main__":
    sys.exit(main())
