# -*- coding: utf-8 -*-
"""Harness: drive the bootstrap phase against the fp8→nvfp4 cast task.

Prerequisite: `tasks/<TASK_NAME>/spec.md` must already exist (produced
by `tests/test_spec.py`). The feature itself lives in `aker.bootstrap`;
this script just wires the harness (logging, pretty-printing, exit
code) around a single `aker.bootstrap.run(task_dir)` call.
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from aker.phases import bootstrap  # noqa: E402
from aker.phases.bootstrap import BootstrapReport  # noqa: E402

TASK_ROOT = ROOT / "tasks"
TASK_NAME = "_try_fp8_nvfp4_cast"


def _format_transcript(report: BootstrapReport) -> str:
    lines = []
    for t in report.review.transcript:
        msg = (t.result.final_message or "").strip()
        tail = msg.splitlines()[-1] if msg else ""
        lines.append(
            f"  [{t.actor:8s}] attempt={t.attempt} "
            f"dur={t.result.duration_sec:6.1f}s exit={t.result.exit_code} "
            f"last_line={tail!r}"
        )
    return "\n".join(lines)


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )

    task_dir = TASK_ROOT / TASK_NAME
    if not (task_dir / "spec.md").exists():
        print(f"ERROR: {task_dir}/spec.md not found. Run tests/test_spec.py first.")
        return 1

    log_path = task_dir / "_bootstrap_log.md"
    print(f"task dir: {task_dir}")
    print(f"log path: {log_path}\n")

    report = bootstrap.run(task_dir, log_path=log_path)

    print(
        f"status={report.status}  "
        f"review.status={report.review.status}  "
        f"attempts={report.review.attempts}  "
        f"turns={len(report.review.transcript)}"
    )
    print(f"worker_session={report.review.worker_session_id}")
    print(f"reviewer_session={report.review.reviewer_session_id}")
    print(_format_transcript(report))
    print(f"\ntranscript written to: {log_path}")

    if report.missing_files:
        print(f"\nmissing files ({len(report.missing_files)}):")
        for f in report.missing_files:
            print(f"  - {f}")
    if report.audit_errors:
        print(f"\naudit errors ({len(report.audit_errors)}):")
        for e in report.audit_errors:
            print(f"  - {e}")

    if report.ok:
        print("\nleaderboard row:")
        print(json.dumps(report.leaderboard_row, indent=2, ensure_ascii=False))
        print(f"\nreport_acc.summary: {report.acc_summary}")
        print(f"report_perf.primary: {report.perf_primary}")
        return 0

    return 2


if __name__ == "__main__":
    sys.exit(main())
