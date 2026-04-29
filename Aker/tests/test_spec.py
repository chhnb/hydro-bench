# -*- coding: utf-8 -*-
"""Harness: exercise the spec phase on a real NL input.

Prints the generated `spec.md` for inspection. The actual feature
lives in `aker.spec`; this is just a thin wrapper.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from aker.phases import spec  # noqa: E402

TASK_ROOT = ROOT / "tasks"
TASK_NAME = "_try_fp8_nvfp4_cast"

USER_INPUT = (
    "在 H20 (hopper) 上实现一个 fp8 e4m3 到 nvfp4 的 cast kernel；"
    "其中 1024 个 fp8 元素共享一个 float 32 类型的量化因子；"
    "16 个 nvfp4 元素共享衣柜 fp8 e4m3 类型的量化因子。"
    "可以认为输入 array 和输出 array 是两个长度规整的 1D的。"
)


def main() -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )

    task_dir = TASK_ROOT / TASK_NAME
    print(f"task dir:   {task_dir}")
    print(f"user input: {USER_INPUT}")
    print()

    report = spec.run(task_dir, description=USER_INPUT)
    print(
        f"status={report.status}  exit={report.codex.exit_code}  "
        f"dur={report.codex.duration_sec:.1f}s"
    )
    print(f"files_created:  {report.codex.files_created}")
    print(f"files_modified: {report.codex.files_modified}")

    if not report.ok:
        print(f"\nFAILED ({report.status})")
        print("\n---- STDERR ----\n" + (report.codex.stderr or ""))
        return 1

    print("\n" + "=" * 70)
    print("spec.md")
    print("=" * 70)
    print(report.spec_path.read_text())
    return 0


if __name__ == "__main__":
    sys.exit(main())
