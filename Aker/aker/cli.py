"""`aker` CLI entry point.

Two subcommands:

- `aker new <task_name> "<description>"`
      Create `tasks/<name>/` if needed, run the spec phase if `spec.md`
      does not yet exist, then run the bootstrap phase if the v0 node
      is not yet present. Idempotent: re-running is safe and will pick
      up wherever a prior run stopped.

- `aker run <task_name> --rounds N`
      Run N iterate rounds against the task directory. Requires the
      task to have been bootstrapped first (`aker new` does that).

Task directories live under `--task-root` (default `./tasks/`).
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from datetime import datetime
from pathlib import Path

from aker.phases import bootstrap, hydro, iterate, spec
from aker.state import guidance as guidance_mod

try:
    from tqdm import tqdm
except ImportError:  # pragma: no cover — tqdm is in install_requires but degrade gracefully
    tqdm = None  # type: ignore[assignment]


def _abs_task_dir(task_root: Path, name: str) -> Path:
    return (task_root / name).resolve()


def _cmd_new(args: argparse.Namespace) -> int:
    task_root = Path(args.task_root).resolve()
    task_dir = _abs_task_dir(task_root, args.task_name)
    task_dir.mkdir(parents=True, exist_ok=True)

    spec_path = task_dir / "spec.md"
    v0_dir = task_dir / "nodes" / "v0_naive_cuda"

    print(f"task dir: {task_dir}")

    # Spec phase — skip if spec.md already exists.
    if spec_path.exists():
        print(f"[spec ] spec.md already present — skipping spec phase")
    else:
        if not args.description:
            print(
                "ERROR: spec.md does not exist and no description was "
                "provided. Pass a description as the third positional "
                "argument so `aker new` can generate spec.md."
            )
            return 1
        print(f"[spec ] generating spec.md from description ({len(args.description)} chars)")
        report = spec.run(
            task_dir,
            description=args.description,
            model=args.model,
            timeout_sec=args.spec_timeout_sec,
        )
        print(
            f"[spec ] status={report.status} exit={report.codex.exit_code} "
            f"dur={report.codex.duration_sec:.1f}s"
        )
        if not report.ok:
            print(f"[spec ] FAILED — inspect {task_dir} for partial output")
            return 2

    # Bootstrap phase — skip only if the full bootstrap contract is
    # already satisfied on disk. A half-finished v0 directory (e.g.
    # worker crashed before running tests) must not be treated as
    # "already done".
    missing, errors = bootstrap.audit(task_dir)
    if not missing and not errors:
        print(f"[boot ] bootstrap already complete — skipping")
        return 0
    if v0_dir.is_dir():
        reasons = []
        if missing:
            reasons.append(f"missing={missing}")
        if errors:
            reasons.append(f"errors={errors}")
        print(
            f"[boot ] {v0_dir.name}/ exists but bootstrap is incomplete "
            f"({'; '.join(reasons)}) — re-running bootstrap"
        )

    print(f"[boot ] running bootstrap (may take several minutes)…")
    br = bootstrap.run(
        task_dir,
        max_retries=args.bootstrap_max_retries,
        log_path=task_dir / "_bootstrap_log.md",
        model=args.model,
        worker_timeout_sec=args.timeout_sec,
        reviewer_timeout_sec=args.timeout_sec,
    )
    print(
        f"[boot ] status={br.status} review={br.review.status} "
        f"attempts={br.review.attempts} turns={len(br.review.transcript)}"
    )
    if br.missing_files:
        print(f"[boot ] missing_files: {br.missing_files}")
    if br.audit_errors:
        print(f"[boot ] audit_errors: {br.audit_errors}")
    if not br.ok:
        return 3

    print("[boot ] OK — leaderboard seeded:")
    print(json.dumps(br.leaderboard_row, indent=2, ensure_ascii=False))
    return 0


def _count_prior_rounds(task_dir: Path) -> int:
    """Count the number of close events in `_reservations.jsonl` — i.e.,
    rounds attempted across all prior `aker run` invocations on this task."""
    rfile = task_dir / "_reservations.jsonl"
    if not rfile.is_file():
        return 0
    n = 0
    for line in rfile.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            evt = json.loads(line)
        except json.JSONDecodeError:
            continue
        if evt.get("event") == "close":
            n += 1
    return n


def _read_v0_and_best(task_dir: Path) -> tuple[float | None, float | None]:
    """Return (v0_runtime_ms, best_runtime_ms) from leaderboard.jsonl.
    Either may be None if the leaderboard is empty / lacks v0."""
    lbf = task_dir / "leaderboard.jsonl"
    if not lbf.is_file():
        return None, None
    v0_ms = None
    best_ms = None
    for line in lbf.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        rt = row.get("runtime_ms_primary")
        if not isinstance(rt, (int, float)) or rt <= 0:
            continue
        if row.get("node_id") == "v0_naive_cuda":
            v0_ms = float(rt)
        if best_ms is None or rt < best_ms:
            best_ms = float(rt)
    return v0_ms, best_ms


def _fmt_ms(v: float | None) -> str:
    if v is None:
        return "?"
    return f"{v:.3f}ms"


def _cmd_run(args: argparse.Namespace) -> int:
    task_root = Path(args.task_root).resolve()
    task_dir = _abs_task_dir(task_root, args.task_name)
    if not (task_dir / "spec.md").exists():
        print(f"ERROR: {task_dir}/spec.md not found. Run `aker new {args.task_name} \"...\"` first.")
        return 1
    if not (task_dir / "nodes" / "v0_naive_cuda").is_dir():
        print(
            f"ERROR: {task_dir}/nodes/v0_naive_cuda/ not found. "
            f"Bootstrap did not finish; re-run `aker new {args.task_name}` "
            f"or `aker hydro-init {args.task_name}`."
        )
        return 1

    # File logging — keep the terminal clean for tqdm.
    log_dir = task_dir / "_iterate_logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%dT%H%M%S")
    log_file = log_dir / f"run_{ts}.log"
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s %(name)s %(levelname)s %(message)s")
    )
    root = logging.getLogger()
    root.handlers = [file_handler]
    root.setLevel(getattr(logging, args.log_level.upper(), logging.INFO))

    prior = _count_prior_rounds(task_dir)
    total = prior + args.rounds
    v0_initial, best_initial = _read_v0_and_best(task_dir)

    # Header — one short block, then the bar takes over.
    print(f"task:    {task_dir.name}")
    print(f"rounds:  {args.rounds} this run; cumulative {prior+1}…{total} of {total}")
    print(f"slots:   {args.parallel} parallel")
    print(f"log:     {log_file}")
    if v0_initial is not None:
        line = f"v0:      {_fmt_ms(v0_initial)} (baseline)"
        if best_initial is not None and best_initial != v0_initial:
            line += f"   best so far: {_fmt_ms(best_initial)} ({v0_initial / best_initial:.2f}x)"
        print(line)
    print()

    pbar = None
    if tqdm is not None:
        pbar = tqdm(
            initial=prior,
            total=total,
            unit="round",
            desc=task_dir.name,
            dynamic_ncols=True,
            mininterval=0.5,
        )

    def _on_round(rep) -> None:
        if pbar is not None:
            pbar.update(1)
            postfix: dict[str, str] = {}
            if rep.status == "OK" and rep.new_node_id:
                postfix["last"] = rep.new_node_id
            else:
                postfix["last"] = f"{rep.status}({rep.new_node_id or '-'})"
            v0_now, best_now = _read_v0_and_best(task_dir)
            if v0_now is not None and best_now is not None:
                postfix["best"] = _fmt_ms(best_now)
                postfix["sp"] = f"{v0_now / best_now:.2f}x"
            pbar.set_postfix(postfix)

    try:
        report = iterate.run(
            task_dir,
            rounds=args.rounds,
            parallel=args.parallel,
            max_retries=args.max_retries,
            model=args.model,
            worker_timeout_sec=args.timeout_sec,
            reviewer_timeout_sec=args.timeout_sec,
            rng_seed=args.rng_seed,
            on_round_done=_on_round,
            slot_log_file=log_file,
        )
    finally:
        if pbar is not None:
            pbar.close()

    # Final summary.
    v0_final, best_final = _read_v0_and_best(task_dir)
    print()
    print(f"finished: {report.num_ok}/{len(report.rounds)} rounds OK in this session")
    if v0_final is not None:
        print(f"v0 baseline: {_fmt_ms(v0_final)}")
    if best_final is not None and v0_final is not None:
        speedup = v0_final / best_final
        print(f"final best : {_fmt_ms(best_final)}  ({speedup:.2f}x speedup vs v0)")
        if best_initial is not None and best_initial > 0:
            delta = best_initial / best_final
            mark = "↓" if delta > 1.0 else ("=" if delta == 1.0 else "↑")
            print(f"this run   : {mark} {delta:.3f}x relative to prior best ({_fmt_ms(best_initial)})")
    if report.successful_nodes:
        print(f"new nodes  : {', '.join(report.successful_nodes)}")
    print(f"log        : {log_file}")

    return 0 if report.num_ok == len(report.rounds) and report.rounds else 2


def _cmd_hydro_init(args: argparse.Namespace) -> int:
    task_root = Path(args.task_root).resolve()
    task_dir = _abs_task_dir(task_root, args.task_name)
    out = hydro.init_task(
        task_dir,
        repo_root=args.repo_root,
        case=args.case,
        steps=args.steps,
        perf_steps=args.perf_steps,
        perf_repeat=args.perf_repeat,
        gpu_arch=args.gpu_arch,
        run_tests=args.run_tests,
    )
    print(f"hydro task dir: {out}")
    print(f"case: {args.case}")
    print(f"steps: {args.steps}")
    if args.run_tests:
        print("v0 reports generated and leaderboard seeded")
    else:
        print("v0 node created; run v0 tests on an A100 before long iteration if you want a seeded leaderboard")
    return 0


def _cmd_hydro_seed(args: argparse.Namespace) -> int:
    task_root = Path(args.task_root).resolve()
    task_dir = _abs_task_dir(task_root, args.task_name)
    result = hydro.seed_v0(task_dir, force=args.force)
    if result.get("skipped"):
        print(f"skipped: {result.get('reason')}")
    else:
        print("seeded v0_naive_cuda:")
        print(json.dumps(result.get("row"), indent=2, ensure_ascii=False))
    return 0


def _cmd_hint(args: argparse.Namespace) -> int:
    task_root = Path(args.task_root).resolve()
    task_dir = _abs_task_dir(task_root, args.task_name)
    if not task_dir.is_dir():
        print(f"ERROR: task dir {task_dir} does not exist; create it with `aker new` first.")
        return 1

    if args.action == "show":
        g = guidance_mod.read(task_dir)
        if g is None:
            print(f"(no guidance.md at {task_dir})")
            return 0
        current = guidance_mod.count_reservation_opens(task_dir)
        if g.is_expired(current):
            print(
                f"guidance.md is EXPIRED "
                f"(created at open #{g.created_at_open_count}, ttl={g.ttl_rounds}, "
                f"current opens={current}). It will be archived on the next `aker run`."
            )
        else:
            print(
                f"guidance.md ACTIVE "
                f"({g.remaining(current)} of {g.ttl_rounds} round(s) remaining; "
                f"created at {g.created_at})\n"
            )
        print("---")
        print(g.body)
        print("---")
        return 0

    if args.action == "clear":
        dest = guidance_mod.archive(task_dir, reason="manual_clear")
        if dest is None:
            print(f"(no guidance.md to clear at {task_dir})")
            return 0
        print(f"archived: {dest}")
        return 0

    # action == "set"
    body = args.body
    if not body:
        body = sys.stdin.read()
    if not body.strip():
        print("ERROR: empty guidance body — pass text as the positional arg or via stdin.")
        return 1

    g = guidance_mod.write(task_dir, body, ttl_rounds=args.for_rounds)
    print(
        f"wrote {task_dir / 'guidance.md'} "
        f"(active for {g.ttl_rounds} round(s) starting from open #{g.created_at_open_count + 1})"
    )
    return 0


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="aker",
        description="LLM-driven CUDA kernel graph exploration.",
    )
    p.add_argument(
        "--task-root",
        default="tasks",
        help="directory containing task subdirectories (default: ./tasks)",
    )
    p.add_argument(
        "--model",
        default=None,
        help="codex model override (default: codex's default)",
    )
    p.add_argument(
        "--timeout-sec",
        type=float,
        default=3600.0,
        help="per-session timeout for bootstrap/iterate (default: 3600)",
    )
    p.add_argument(
        "--log-level",
        default="INFO",
        help="logging level (default: INFO)",
    )

    sub = p.add_subparsers(dest="subcmd", required=True)

    new_p = sub.add_parser(
        "new",
        help="create + spec + bootstrap a task (idempotent)",
    )
    new_p.add_argument("task_name", help="directory name under --task-root")
    new_p.add_argument(
        "description",
        nargs="?",
        default=None,
        help="natural-language description (required on first run; "
             "ignored if spec.md already exists)",
    )
    new_p.add_argument(
        "--spec-timeout-sec",
        type=float,
        default=1800.0,
        help="timeout for the spec-generator codex call (default: 1800)",
    )
    new_p.add_argument(
        "--bootstrap-max-retries",
        type=int,
        default=3,
        help="max worker↔reviewer retries in bootstrap (default: 3)",
    )
    new_p.set_defaults(func=_cmd_new)

    hydro_p = sub.add_parser(
        "hydro-init",
        help="create a native hydro-cal optimization task",
    )
    hydro_p.add_argument("task_name", help="directory name under --task-root")
    hydro_p.add_argument(
        "--repo-root",
        default=None,
        help="hydro-bench repo root (default: auto-detect from cwd)",
    )
    hydro_p.add_argument(
        "--case",
        default="F2_207K_fp64",
        help="alignment/benchmark case (default: F2_207K_fp64)",
    )
    hydro_p.add_argument(
        "--steps",
        default="1,10,100,899,7199",
        help="correctness checkpoints (default: 1,10,100,899,7199)",
    )
    hydro_p.add_argument(
        "--perf-steps",
        type=int,
        default=100,
        help="benchmark steps per perf repeat (default: 100)",
    )
    hydro_p.add_argument(
        "--perf-repeat",
        type=int,
        default=3,
        help="benchmark repeats (default: 3)",
    )
    hydro_p.add_argument(
        "--gpu-arch",
        default="sm_80",
        help="nvcc target architecture (default: sm_80)",
    )
    hydro_p.add_argument(
        "--run-tests",
        action="store_true",
        help="run v0 test_acc/test_perf immediately and seed leaderboard",
    )
    hydro_p.set_defaults(func=_cmd_hydro_init)

    seed_p = sub.add_parser(
        "hydro-seed",
        help="run native hydro v0 tests and seed the leaderboard",
    )
    seed_p.add_argument("task_name", help="directory name under --task-root")
    seed_p.add_argument(
        "--force",
        action="store_true",
        help="append a fresh v0 row even if one already exists",
    )
    seed_p.set_defaults(func=_cmd_hydro_seed)

    run_p = sub.add_parser(
        "run",
        help="iterate the kernel graph N rounds",
    )
    run_p.add_argument("task_name", help="directory name under --task-root")
    run_p.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="number of iterate rounds (default: 1)",
    )
    run_p.add_argument(
        "--max-retries",
        type=int,
        default=5,
        help="max worker↔reviewer retries per round (default: 5)",
    )
    run_p.add_argument(
        "--parallel",
        type=int,
        default=1,
        help="number of concurrent worker slots (default: 1; recommend 1-5)",
    )
    run_p.add_argument(
        "--rng-seed",
        type=int,
        default=None,
        help="seed for the worker-session lifespan RNG (default: random)",
    )
    run_p.set_defaults(func=_cmd_run)

    hint_p = sub.add_parser(
        "hint",
        help="manage human guidance for a task (TTL'd; auto-expires)",
    )
    hint_p.add_argument("task_name", help="directory name under --task-root")
    hint_p.add_argument(
        "body",
        nargs="?",
        default=None,
        help="guidance text (optional; if omitted with --action set, read from stdin)",
    )
    hint_p.add_argument(
        "--action",
        choices=("set", "show", "clear"),
        default="set",
        help="set new guidance (default), show current, or clear it",
    )
    hint_p.add_argument(
        "--for",
        dest="for_rounds",
        type=int,
        default=10,
        help="TTL in rounds for `--action set` (default: 10). After this many "
             "reservation opens the guidance auto-archives.",
    )
    hint_p.set_defaults(func=_cmd_hint)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    # Default logging goes to stderr. `_cmd_run` overrides this to a
    # file so the tqdm bar isn't interleaved with INFO log lines.
    logging.basicConfig(
        level=getattr(logging, args.log_level.upper(), logging.INFO),
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
