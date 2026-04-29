"""`akerjob` — internal CLI used by worker sessions to submit GPU jobs.

This binary runs inside a codex sandbox. It is NOT intended for end-user
invocation (the end user talks to `aker ...`). It reads the broker socket
path and the task directory from environment variables injected by
`aker run` when the slot process was spawned, submits a blocking job
request, prints the subprocess stdout / stderr transparently to the
caller, and appends a trailing `[akerjob] {...}` line on stderr with job
metadata.

See dev/parallel.md §6.2.

Env contract (set by `aker run` → slot → codex subprocess):

    AKER_BROKER_SOCK   absolute path to the broker's unix socket
    AKER_TASK_DIR      absolute path to the task directory

Exit codes:

    0    job ran, subprocess returned 0
    124  job exceeded the broker's per-kind timeout (TIMEOUT)
    97   broker unreachable / heartbeat stale (BrokerGone)
    2    invalid invocation / env not set
    1    other failures (subprocess nonzero propagated when available)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from aker.gpu.client import EXIT_BROKER_GONE, BrokerGone, submit


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="akerjob",
        description=(
            "Submit a GPU job to the aker broker. Intended for worker "
            "sessions inside a codex sandbox; requires AKER_BROKER_SOCK "
            "and AKER_TASK_DIR in the environment."
        ),
    )
    sub = parser.add_subparsers(dest="kind", required=True)

    for kind in ("test_acc", "test_perf"):
        p = sub.add_parser(kind, help=f"Run {kind} via the broker.")
        p.add_argument("--node", required=True, metavar="NODE_ID")
        p.add_argument(
            "--client-timeout-sec",
            type=float,
            default=1800.0,
            help="Max time (s) willing to wait for the broker to respond.",
        )

    profile = sub.add_parser(
        "profile",
        help="Run a GPU-bound profiler via the broker (ncu only; "
             "for SASS use `cuobjdump` directly — it is a static tool).",
    )
    profile.add_argument(
        "tool", choices=("ncu",), help="Profiling tool to invoke."
    )
    profile.add_argument("--node", required=True, metavar="NODE_ID")
    profile.add_argument("--sections", default=None)
    profile.add_argument("--client-timeout-sec", type=float, default=1800.0)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)

    sock_path = os.environ.get("AKER_BROKER_SOCK")
    task_dir = os.environ.get("AKER_TASK_DIR")
    if not sock_path or not task_dir:
        sys.stderr.write(
            "akerjob: AKER_BROKER_SOCK / AKER_TASK_DIR not set in environment.\n"
            "This tool must be run inside a worker session spawned by `aker run`.\n"
        )
        return 2

    if args.kind == "profile":
        kind = f"profile_{args.tool}"
        extra_args: list[str] = []
        if args.sections:
            extra_args += ["--sections", args.sections]
    else:
        kind = args.kind
        extra_args = []

    heartbeat_path = Path(sock_path).with_suffix(".heartbeat")

    try:
        resp = submit(
            sock_path,
            kind=kind,
            node_id=args.node,
            task_dir=task_dir,
            extra_args=extra_args,
            client_timeout_sec=args.client_timeout_sec,
            heartbeat_path=heartbeat_path,
        )
    except BrokerGone as e:
        sys.stderr.write(f"akerjob: broker gone ({e})\n")
        return EXIT_BROKER_GONE

    # Transparent passthrough of the subprocess output.
    if resp.stdout:
        sys.stdout.write(resp.stdout)
        if not resp.stdout.endswith("\n"):
            sys.stdout.write("\n")
    if resp.stderr:
        sys.stderr.write(resp.stderr)
        if not resp.stderr.endswith("\n"):
            sys.stderr.write("\n")

    meta = {
        "job_id": resp.job_id,
        "status": resp.status,
        "queue_wait_ms": resp.queue_wait_ms,
        "run_ms": resp.run_ms,
        "returncode": resp.returncode,
    }
    sys.stderr.write(f"[akerjob] {json.dumps(meta)}\n")

    if resp.status == "OK":
        return 0
    if resp.status == "TIMEOUT":
        return 124
    if resp.status == "SUBPROCESS_NONZERO":
        return resp.returncode if isinstance(resp.returncode, int) and resp.returncode != 0 else 1
    if resp.status == "NOT_IMPLEMENTED":
        return 95
    # BROKER_ERROR and anything else
    return 1


if __name__ == "__main__":
    sys.exit(main())
