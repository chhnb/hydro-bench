"""Iterate phase — grow the kernel graph by adding nodes.

Parallel-capable: `run(task_dir, rounds=R, parallel=N)` spawns N long-
lived slot processes that each consume rounds from a multiprocessing
queue and feed their results back via another queue. Exactly one GPU
broker runs for the whole invocation and serializes all GPU work.

See dev/parallel.md — especially §6 component design and §6.11 crash
handling. This module implements:

- Device-level flock with stale-PID takeover (§6.7).
- Broker subprocess lifecycle tied to aker-run (§6.1 + P5).
- Reservation-driven round flow with N allocation + close status
  enum (§6.3 + §6.10).
- ProcessPoolExecutor-equivalent: raw Process + Queue so each slot
  can preserve its own codex-session carry across rounds (D17 / P14).
- `spawn` start method (P16) to avoid inheriting parent CUDA state.
- `CUDA_VISIBLE_DEVICES=""` injected into codex subprocess env so the
  LLM can only touch the GPU through `akerjob` (P17).
"""

from __future__ import annotations

import atexit
import fcntl
import hashlib
import json
import logging
import math
import multiprocessing as mp
import os
import queue as _queue
import random
import signal
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from aker.infra.backend import (
    SANDBOX_DANGER_FULL_ACCESS,
    SANDBOX_READ_ONLY,
    SANDBOX_WORKSPACE_WRITE,
    AgentSession,
    make_session,
)
from aker.gpu.client import BrokerGone, JobResponse, submit
from aker.state import guidance as guidance_mod
from aker.state.graph import (
    NodeRecord,
    backfill_notes_md,
    backfill_report_node_ids,
    backfill_v0_meta,
    format_graph_summary,
    patch_node_id_in_reports,
    scan_in_flight,
    scan_nodes,
)
from aker.state.leaderboard import LeaderboardError, commit_row, regenerate_md
from aker.state.reservation import (
    CLOSE_AUDIT_FAILED,
    CLOSE_BAILED,
    CLOSE_COMMITTED,
    CLOSE_CRASHED,
    close_all_open,
    close_reservation,
    open_reservation,
    sweep_nonstandard_staging,
    sweep_stale,
)
from aker.phases.review_loop import (
    ReviewLoopResult,
    ReviewPrompts,
    run_review_loop,
)

log = logging.getLogger(__name__)

PROMPT_DIR = Path(__file__).parent.parent / "prompts"

GRAPH_SUMMARY_PLACEHOLDER = "<<GRAPH_SUMMARY>>"
ASSIGNED_N_PLACEHOLDER = "<<ASSIGNED_N>>"
HUMAN_GUIDANCE_PLACEHOLDER = "<<HUMAN_GUIDANCE>>"

POISON = None  # poison pill sentinel on the work queue


# ----------------------------- reports ----------------------------------


@dataclass
class RoundReport:
    """One round outcome (per reservation).

    `status` is one of:
      - "OK"               — review PASS, on-disk audit clean, row committed
      - "FAIL_REVIEW"      — review loop did not reach PASS
      - "FAIL_AUDIT"       — review PASS but §6.10 audit violated
      - "FAIL_BAILED"      — LLM explicitly gave up; no node dir on disk
      - "FAIL_SLOT_CRASH"  — slot / broker died; partial or no node
    """

    round_index: int
    slot_id: str
    reservation_id: str
    reserved_n: int
    status: str
    new_node_id: str | None = None
    audit_errors: list[str] = field(default_factory=list)
    review_status: str | None = None
    review_attempts: int | None = None

    @property
    def ok(self) -> bool:
        return self.status == "OK"


@dataclass
class IterateReport:
    rounds: list[RoundReport] = field(default_factory=list)

    @property
    def successful_nodes(self) -> list[str]:
        return [r.new_node_id for r in self.rounds if r.ok and r.new_node_id]

    @property
    def num_ok(self) -> int:
        return sum(1 for r in self.rounds if r.ok)


# ----------------------------- public entry -----------------------------


def run(
    task_dir: Path | str,
    *,
    rounds: int = 1,
    parallel: int = 1,
    max_retries: int = 5,
    model: str | None = None,
    worker_timeout_sec: float = 3600.0,
    reviewer_timeout_sec: float = 3600.0,
    log_dir: Path | str | None = None,
    worker_session_min_rounds: int = 1,
    worker_session_max_rounds: int = 5,
    rng_seed: int | None = None,
    reservation_timeout_sec: float = 3600.0,
    on_round_done: Callable[[RoundReport], None] | None = None,
    slot_log_file: Path | str | None = None,
) -> IterateReport:
    """Run `rounds` total iterate cycles on `task_dir`, with `parallel` slots.

    `on_round_done` is invoked once per RoundReport as soon as it lands
    in the result queue (or, for slot-crash synthesized reports, when the
    main loop notices the dead slot). Used by the CLI to drive a tqdm
    progress bar; safe to leave None.

    `slot_log_file`, if set, is the file each slot's logging.basicConfig
    will write to — keeps slot output off stderr so the CLI's tqdm bar
    is not interleaved with log lines.
    """
    task_dir = Path(task_dir).resolve()
    if rounds < 1:
        raise ValueError(f"rounds must be >= 1, got {rounds}")
    _preflight(
        task_dir,
        parallel=parallel,
        worker_session_min_rounds=worker_session_min_rounds,
        worker_session_max_rounds=worker_session_max_rounds,
    )

    # Backfills (ported from the serial version — still valid in parallel).
    backfill_v0_meta(task_dir)
    bf = backfill_notes_md(task_dir)
    if bf:
        log.info("iterate: backfilled notes.md for %d node(s): %s", len(bf), bf)
    fixed_reports = backfill_report_node_ids(task_dir)
    if fixed_reports:
        log.info(
            "iterate: rewrote stale node_id in report_*.json for %d node(s): %s",
            len(fixed_reports),
            fixed_reports,
        )

    if log_dir is None:
        log_dir = task_dir / "_iterate_logs"
    log_dir = Path(log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)

    # Device lock (P13).
    device_lock_fd = _acquire_device_lock()

    # Sweep stale reservations / orphans from prior aborted runs.
    try:
        closed = close_all_open(
            task_dir, status=CLOSE_CRASHED, reason="prev_aker_run_exit"
        )
        if closed:
            log.info(
                "iterate: closed %d stale open reservation(s) from prior run: %s",
                len(closed),
                [r.reserved_n for r in closed],
            )
        swept = sweep_stale(task_dir, reservation_timeout_sec=0.0)
        if swept:
            log.info(
                "iterate: swept %d stale orphan(s): %s",
                len(swept),
                [r.reserved_n for r in swept],
            )
        # Also evict any non-standard `.v<N>_*` staging dirs —
        # LLM-invented suffixes (e.g. `.peer_backup`) or stale `.tmp`s
        # for closed reservations.
        moved = sweep_nonstandard_staging(task_dir)
        if moved:
            log.info(
                "iterate: relocated %d non-standard staging dir(s) to _orphans: %s",
                len(moved),
                moved,
            )
    except Exception:
        log.exception("iterate: stale-sweep prelude failed (continuing)")

    # Broker + slots.
    broker_proc = _spawn_broker(task_dir)

    atexit_registered = False

    def _finalize() -> None:
        try:
            close_all_open(task_dir, status=CLOSE_CRASHED, reason="aker_run_exit")
        except Exception:
            log.exception("iterate: close_all_open in finalize failed")
        _terminate_broker(broker_proc)

    try:
        atexit.register(_finalize)
        atexit_registered = True

        report = _drive_rounds(
            task_dir=task_dir,
            rounds=rounds,
            parallel=parallel,
            max_retries=max_retries,
            model=model,
            worker_timeout_sec=worker_timeout_sec,
            reviewer_timeout_sec=reviewer_timeout_sec,
            log_dir=log_dir,
            worker_session_min_rounds=worker_session_min_rounds,
            worker_session_max_rounds=worker_session_max_rounds,
            rng_seed=rng_seed,
            reservation_timeout_sec=reservation_timeout_sec,
            broker_proc=broker_proc,
            on_round_done=on_round_done,
            slot_log_file=str(slot_log_file) if slot_log_file else None,
        )
    finally:
        _finalize()
        if atexit_registered:
            try:
                atexit.unregister(_finalize)
            except Exception:
                pass
        try:
            os.close(device_lock_fd)
        except OSError:
            pass

    return report


# ----------------------------- preflight / locks ------------------------


def _preflight(
    task_dir: Path,
    *,
    parallel: int,
    worker_session_min_rounds: int,
    worker_session_max_rounds: int,
) -> None:
    if not (task_dir / "spec.md").exists():
        raise FileNotFoundError(f"spec.md not found in {task_dir}")
    if not (task_dir / "nodes").is_dir():
        raise FileNotFoundError(f"{task_dir}/nodes/ missing — run bootstrap first")
    if parallel < 1:
        raise ValueError(f"parallel must be >= 1, got {parallel}")
    if worker_session_min_rounds < 1 or worker_session_max_rounds < worker_session_min_rounds:
        raise ValueError(
            "require 1 <= worker_session_min_rounds <= worker_session_max_rounds; "
            f"got [{worker_session_min_rounds}, {worker_session_max_rounds}]"
        )


def _device_lock_path() -> str:
    raw = os.environ.get("CUDA_VISIBLE_DEVICES", "0")
    parts = sorted(p.strip() for p in raw.split(",") if p.strip())
    norm = "-".join(parts) if parts else "0"
    if len(norm) > 32:
        norm = hashlib.sha1(norm.encode()).hexdigest()[:16]
    return f"/tmp/aker_gpu_{norm}.lock"


def _acquire_device_lock() -> int:
    """§6.7 — per-GPU flock with stale-PID takeover (v3)."""
    path = _device_lock_path()
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # Locked — probe holder liveness.
        try:
            os.lseek(fd, 0, os.SEEK_SET)
            prev_pid_str = os.read(fd, 64).decode("utf-8", errors="replace").strip()
            prev_pid = int(prev_pid_str)
            os.kill(prev_pid, 0)
            os.close(fd)
            sys.exit(
                f"GPU device {os.environ.get('CUDA_VISIBLE_DEVICES', '(default)')!r} "
                f"already managed by aker run PID {prev_pid}"
            )
        except (ValueError, ProcessLookupError):
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    os.lseek(fd, 0, os.SEEK_SET)
    os.ftruncate(fd, 0)
    os.write(fd, f"{os.getpid()}\n".encode())
    os.fsync(fd)
    return fd


# ----------------------------- broker lifecycle -------------------------


def _spawn_broker(task_dir: Path) -> subprocess.Popen:
    """Start a broker child process in its own session, wait for socket."""
    env = os.environ.copy()
    sock_path = task_dir / ".broker.sock"
    # Remove any stale socket (e.g. from a previous SIGKILL).
    try:
        sock_path.unlink()
    except FileNotFoundError:
        pass

    proc = subprocess.Popen(
        [sys.executable, "-m", "aker.gpu.broker", str(task_dir)],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    # Wait for socket to appear.
    deadline = time.monotonic() + 15.0
    while time.monotonic() < deadline:
        if sock_path.exists():
            return proc
        if proc.poll() is not None:
            stderr = (proc.stderr.read() if proc.stderr else b"").decode(errors="replace")
            raise RuntimeError(
                f"broker exited before socket appeared (rc={proc.returncode})\n{stderr}"
            )
        time.sleep(0.1)
    _terminate_broker(proc)
    raise RuntimeError(f"broker did not create socket within 15s at {sock_path}")


def _task_mode(task_dir: Path) -> str:
    cfg_path = task_dir / "task_config.json"
    if not cfg_path.is_file():
        return "torch_extension"
    try:
        cfg = json.loads(cfg_path.read_text())
    except json.JSONDecodeError:
        return "torch_extension"
    return str(cfg.get("mode") or "torch_extension")


def _terminate_broker(proc: subprocess.Popen | None) -> None:
    if proc is None:
        return
    if proc.poll() is not None:
        return
    try:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)
    except Exception:
        log.exception("iterate: broker termination error")


# ----------------------------- prompt loading ---------------------------


def _load_prompts(
    task_dir: Path,
    graph_summary: str,
    assigned_n: int,
    human_guidance_block: str = "",
) -> ReviewPrompts:
    n_str = str(assigned_n)
    mode = _task_mode(task_dir)
    if mode == "native_hydro":
        worker_name = "hydro_iterate_worker.md"
        reviewer_name = "hydro_iterate_reviewer.md"
        worker_fix_name = "hydro_iterate_worker_fix.md"
        reviewer_recheck_name = "hydro_iterate_reviewer_recheck.md"
    else:
        worker_name = "iterate_worker.md"
        reviewer_name = "iterate_reviewer.md"
        worker_fix_name = "iterate_worker_fix.md"
        reviewer_recheck_name = "iterate_reviewer_recheck.md"

    worker_initial = (PROMPT_DIR / worker_name).read_text()
    if GRAPH_SUMMARY_PLACEHOLDER not in worker_initial:
        raise ValueError(f"iterate_worker.md must contain {GRAPH_SUMMARY_PLACEHOLDER}")
    if ASSIGNED_N_PLACEHOLDER not in worker_initial:
        raise ValueError(f"iterate_worker.md must contain {ASSIGNED_N_PLACEHOLDER}")
    if HUMAN_GUIDANCE_PLACEHOLDER not in worker_initial:
        raise ValueError(f"iterate_worker.md must contain {HUMAN_GUIDANCE_PLACEHOLDER}")
    worker_initial = (
        worker_initial.replace(GRAPH_SUMMARY_PLACEHOLDER, graph_summary)
        .replace(ASSIGNED_N_PLACEHOLDER, n_str)
        .replace(HUMAN_GUIDANCE_PLACEHOLDER, human_guidance_block)
    )

    # Reviewer prompts also need the assigned N so they don't guess
    # from the filesystem (which, under parallel mode, will contain
    # peer workers' .v<M>_*.tmp staging dirs that mislead inference).
    reviewer_initial = (PROMPT_DIR / reviewer_name).read_text()
    if ASSIGNED_N_PLACEHOLDER not in reviewer_initial:
        raise ValueError(f"iterate_reviewer.md must contain {ASSIGNED_N_PLACEHOLDER}")
    reviewer_initial = reviewer_initial.replace(ASSIGNED_N_PLACEHOLDER, n_str)

    reviewer_recheck = (PROMPT_DIR / reviewer_recheck_name).read_text()
    if ASSIGNED_N_PLACEHOLDER not in reviewer_recheck:
        raise ValueError(
            f"iterate_reviewer_recheck.md must contain {ASSIGNED_N_PLACEHOLDER}"
        )
    reviewer_recheck = reviewer_recheck.replace(ASSIGNED_N_PLACEHOLDER, n_str)

    return ReviewPrompts(
        worker_initial=worker_initial,
        reviewer_initial=reviewer_initial,
        worker_fix_template=(PROMPT_DIR / worker_fix_name).read_text(),
        reviewer_recheck_template=reviewer_recheck,
    )


# ----------------------------- slot process -----------------------------


@dataclass
class _SlotConfig:
    task_dir: str
    log_dir: str
    broker_sock: str
    max_retries: int
    model: str | None
    worker_timeout_sec: float
    reviewer_timeout_sec: float
    worker_session_min_rounds: int
    worker_session_max_rounds: int
    base_seed: int | None
    log_file: str | None = None


def _slot_main(
    slot_id: str,
    cfg: _SlotConfig,
    work_q: "mp.Queue",
    result_q: "mp.Queue",
) -> None:
    """Long-lived slot process. Consumes round ids until it gets POISON."""
    log_kwargs: dict = dict(
        level=os.environ.get("AKER_LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s slot-" + slot_id + " %(levelname)s %(message)s",
    )
    if cfg.log_file:
        # All slots share the same file. POSIX appends are atomic for
        # short lines; tqdm's stderr stays clean.
        log_kwargs["handlers"] = [logging.FileHandler(cfg.log_file)]
    logging.basicConfig(**log_kwargs)
    signal.signal(signal.SIGTERM, lambda _s, _f: sys.exit(0))

    task_dir = Path(cfg.task_dir)
    log_dir = Path(cfg.log_dir)

    # Derive a stable per-slot RNG seed from base_seed + slot_id.
    if cfg.base_seed is None:
        rng = random.Random()
    else:
        seed = int(hashlib.sha256(f"{cfg.base_seed}:{slot_id}".encode()).hexdigest()[:12], 16)
        rng = random.Random(seed)

    worker_session: AgentSession | None = None
    worker_remaining = 0

    # Env we inject into agent subprocesses (codex or claude): CUDA blinded,
    # broker endpoint.
    agent_env = {
        "AKER_BROKER_SOCK": cfg.broker_sock,
        "AKER_TASK_DIR": str(task_dir),
        "CUDA_VISIBLE_DEVICES": "",
    }

    while True:
        try:
            msg = work_q.get(timeout=1.0)
        except _queue.Empty:
            continue
        if msg is POISON:
            break
        round_index = msg

        result = _slot_run_one_round(
            slot_id=slot_id,
            round_index=round_index,
            task_dir=task_dir,
            log_dir=log_dir,
            cfg=cfg,
            rng=rng,
            agent_env=agent_env,
            worker_session=worker_session,
            worker_remaining=worker_remaining,
        )
        # result is (RoundReport, worker_session_next, worker_remaining_next)
        report, worker_session, worker_remaining = result
        result_q.put(report)
        # If broker went missing we cannot continue.
        if report.status == "FAIL_SLOT_CRASH":
            break


def _slot_run_one_round(
    *,
    slot_id: str,
    round_index: int,
    task_dir: Path,
    log_dir: Path,
    cfg: _SlotConfig,
    rng: random.Random,
    agent_env: dict[str, str],
    worker_session: AgentSession | None,
    worker_remaining: int,
) -> tuple[RoundReport, AgentSession | None, int]:
    reservation = open_reservation(task_dir, slot_id=slot_id)
    log.info(
        "iterate: slot %s round %d reservation=%s N=%d",
        slot_id,
        round_index,
        reservation.reservation_id,
        reservation.reserved_n,
    )

    try:
        records_before = scan_nodes(task_dir)
        in_flight = scan_in_flight(task_dir)
        summary = format_graph_summary(records_before, in_flight)
        # Read + auto-archive expired human guidance. The check happens
        # AFTER our reservation was opened, so the open count includes
        # this round — TTL semantics: "next N reservation opens see it".
        guidance_block = guidance_mod.render_for_prompt(task_dir)
        prompts = _load_prompts(task_dir, summary, reservation.reserved_n, guidance_block)

        worker_sandbox = (
            SANDBOX_WORKSPACE_WRITE
            if _task_mode(task_dir) == "native_hydro"
            else SANDBOX_DANGER_FULL_ACCESS
        )
        if worker_session is None or worker_remaining <= 0:
            worker_session = make_session(
                cwd=task_dir,
                sandbox=worker_sandbox,
                timeout_sec=cfg.worker_timeout_sec,
                model=cfg.model,
                extra_env=agent_env,
            )
            worker_remaining = rng.randint(
                cfg.worker_session_min_rounds, cfg.worker_session_max_rounds
            )
            log.info(
                "iterate: slot %s new worker session (lifespan=%d rounds)",
                slot_id,
                worker_remaining,
            )

        log_path = log_dir / f"{reservation.reservation_id}.md"
        after_worker_turn = None
        if _task_mode(task_dir) == "native_hydro":
            after_worker_turn = (
                lambda _turn, _result: _host_finalize_native_hydro_candidate(
                    task_dir=task_dir,
                    reserved_n=reservation.reserved_n,
                    broker_sock=cfg.broker_sock,
                    timeout_sec=cfg.worker_timeout_sec,
                )
            )
        review = run_review_loop(
            task_dir=task_dir,
            prompts=prompts,
            max_retries=cfg.max_retries,
            worker_sandbox=worker_sandbox,
            reviewer_sandbox=SANDBOX_READ_ONLY,
            worker_timeout_sec=cfg.worker_timeout_sec,
            reviewer_timeout_sec=cfg.reviewer_timeout_sec,
            log_path=log_path,
            model=cfg.model,
            worker=worker_session,
            after_worker_turn=after_worker_turn,
        )
        worker_remaining -= 1
        if review.status == "FAIL_WORKER_CRASH":
            worker_session = None  # force fresh next round
            worker_remaining = 0

        return (
            _finalize_round(
                task_dir=task_dir,
                slot_id=slot_id,
                round_index=round_index,
                reservation=reservation,
                review=review,
            ),
            worker_session,
            worker_remaining,
        )
    except Exception as e:  # noqa: BLE001
        log.exception("iterate: slot %s round %d crashed", slot_id, round_index)
        try:
            close_reservation(
                task_dir,
                reservation.reservation_id,
                status=CLOSE_CRASHED,
                reason=f"slot_error: {type(e).__name__}",
            )
        except Exception:
            log.exception("iterate: failed to close crashed reservation")
        return (
            RoundReport(
                round_index=round_index,
                slot_id=slot_id,
                reservation_id=reservation.reservation_id,
                reserved_n=reservation.reserved_n,
                status="FAIL_SLOT_CRASH",
                audit_errors=[f"{type(e).__name__}: {e}"],
            ),
            None,
            0,
        )


def _finalize_round(
    *,
    task_dir: Path,
    slot_id: str,
    round_index: int,
    reservation,
    review: ReviewLoopResult,
) -> RoundReport:
    new_node_dir = _find_committed_dir(task_dir, reservation.reserved_n)
    if new_node_dir is not None:
        # Worker ran tests against `.v<N>_<tag>.tmp` then renamed; the
        # report_*.json `node_id` field still holds the stale staging
        # name. Rewrite to match the committed directory name before
        # audit reads the reports.
        try:
            patch_node_id_in_reports(new_node_dir)
        except Exception:  # noqa: BLE001
            log.exception("iterate: patch_node_id_in_reports failed for %s", new_node_dir.name)
    base = dict(
        round_index=round_index,
        slot_id=slot_id,
        reservation_id=reservation.reservation_id,
        reserved_n=reservation.reserved_n,
        review_status=review.status,
        review_attempts=review.attempts,
    )

    if review.status != "OK":
        # Review loop didn't reach PASS. If the worker produced a dir, keep
        # it and label the close accordingly; else it's a bail.
        if new_node_dir is None:
            close_reservation(
                task_dir,
                reservation.reservation_id,
                status=CLOSE_BAILED,
                reason=f"review:{review.status}",
            )
            return RoundReport(
                status="FAIL_REVIEW",
                new_node_id=None,
                audit_errors=[f"review={review.status}, no node on disk"],
                **base,
            )
        else:
            close_reservation(
                task_dir,
                reservation.reservation_id,
                status=CLOSE_AUDIT_FAILED,
                reason=f"review:{review.status}",
            )
            return RoundReport(
                status="FAIL_REVIEW",
                new_node_id=new_node_dir.name,
                audit_errors=[f"review={review.status}"],
                **base,
            )

    # review.status == OK
    if new_node_dir is None:
        close_reservation(
            task_dir,
            reservation.reservation_id,
            status=CLOSE_BAILED,
            reason="review_ok_but_no_node",
        )
        return RoundReport(
            status="FAIL_BAILED",
            new_node_id=None,
            audit_errors=["review PASS but no v<N>_<tag>/ on disk"],
            **base,
        )

    errors = audit(task_dir, reservation.reserved_n, new_node_dir)
    if errors:
        close_reservation(
            task_dir,
            reservation.reservation_id,
            status=CLOSE_AUDIT_FAILED,
            reason="; ".join(errors)[:300],
        )
        return RoundReport(
            status="FAIL_AUDIT",
            new_node_id=new_node_dir.name,
            audit_errors=errors,
            **base,
        )

    # OK + clean audit. Commit leaderboard row (if attempt_status=OK) and
    # close reservation committed.
    try:
        meta = json.loads((new_node_dir / "meta.json").read_text())
        if meta.get("attempt_status") == "OK":
            commit_row(task_dir, new_node_dir.name)
        else:
            # FAIL attempts still get a committed reservation (failure data
            # is preserved) — but no leaderboard row (consistent with P12).
            regenerate_md(task_dir)
    except LeaderboardError as e:
        close_reservation(
            task_dir,
            reservation.reservation_id,
            status=CLOSE_AUDIT_FAILED,
            reason=f"leaderboard: {e}",
        )
        return RoundReport(
            status="FAIL_AUDIT",
            new_node_id=new_node_dir.name,
            audit_errors=[f"leaderboard assembly: {e}"],
            **base,
        )
    except Exception as e:  # noqa: BLE001
        log.exception("iterate: leaderboard commit failed")
        close_reservation(
            task_dir,
            reservation.reservation_id,
            status=CLOSE_AUDIT_FAILED,
            reason=f"leaderboard_unexpected: {type(e).__name__}",
        )
        return RoundReport(
            status="FAIL_AUDIT",
            new_node_id=new_node_dir.name,
            audit_errors=[f"leaderboard unexpected: {e}"],
            **base,
        )

    # Write audit.json for debugging (Python-written, non-LLM; §6.10).
    try:
        (new_node_dir / "audit.json").write_text(
            json.dumps(
                {
                    "reservation_id": reservation.reservation_id,
                    "slot_id": slot_id,
                    "audited_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                    "errors": [],
                    "review_attempts": review.attempts,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
    except OSError:
        log.warning("iterate: could not write audit.json for %s", new_node_dir.name)

    close_reservation(
        task_dir,
        reservation.reservation_id,
        status=CLOSE_COMMITTED,
    )
    return RoundReport(
        status="OK",
        new_node_id=new_node_dir.name,
        audit_errors=[],
        **base,
    )


# ----------------------------- audit ------------------------------------


def _find_committed_dir(task_dir: Path, reserved_n: int) -> Path | None:
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return None
    prefix = f"v{reserved_n}_"
    for child in nodes_dir.iterdir():
        if not child.is_dir() or child.name.startswith("."):
            continue
        if child.name.startswith(prefix):
            return child
    return None


def _host_finalize_native_hydro_candidate(
    *,
    task_dir: Path,
    reserved_n: int,
    broker_sock: str,
    timeout_sec: float,
) -> None:
    """Validate and commit a native-hydro candidate outside the agent sandbox.

    Some hosted agent sessions cannot run Bash without elevated permissions.
    For native-hydro tasks, the agent only needs to write candidate files; the
    trusted Aker slot can run brokered validation and perform the final rename.
    """
    nodes_dir = task_dir / "nodes"
    if not nodes_dir.is_dir():
        return

    candidates = _native_hydro_candidate_dirs(nodes_dir, reserved_n)
    if not candidates:
        log.info("native_hydro host finalize: no v%d candidate yet", reserved_n)
        return
    if len(candidates) > 1:
        log.warning(
            "native_hydro host finalize: multiple v%d candidates: %s",
            reserved_n,
            [c.name for c in candidates],
        )
        return

    candidate_dir = candidates[0]
    committed_name = _native_hydro_committed_name(candidate_dir)
    committed_dir = nodes_dir / committed_name

    missing = [
        rel for rel in ("kernel.cu", "meta.json", "notes.md")
        if not (candidate_dir / rel).is_file()
    ]
    if missing:
        log.info(
            "native_hydro host finalize: %s missing required file(s): %s",
            candidate_dir.name,
            missing,
        )
        return

    meta_path = candidate_dir / "meta.json"
    try:
        meta = json.loads(meta_path.read_text())
    except json.JSONDecodeError as e:
        log.warning(
            "native_hydro host finalize: %s/meta.json is not valid JSON: %s",
            candidate_dir.name,
            e,
        )
        return

    meta["node_id"] = committed_name
    validation_lines: list[str] = []
    needs_validation = _native_hydro_needs_host_validation(candidate_dir, meta)
    if needs_validation:
        ok, failure_reason = _run_native_hydro_host_validation(
            task_dir=task_dir,
            node_arg=candidate_dir.name,
            broker_sock=broker_sock,
            timeout_sec=timeout_sec,
            validation_lines=validation_lines,
        )
        if ok:
            meta["attempt_status"] = "OK"
            meta.pop("failure_reason", None)
        else:
            meta["attempt_status"] = "FAIL"
            meta["failure_reason"] = failure_reason
    else:
        validation_lines.append("host validation: existing OK reports reused")

    meta_path.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    _append_host_validation_notes(candidate_dir / "notes.md", validation_lines)

    if candidate_dir.name.startswith("."):
        if committed_dir.exists():
            log.warning(
                "native_hydro host finalize: cannot rename %s to existing %s",
                candidate_dir.name,
                committed_dir.name,
            )
            return
        candidate_dir.rename(committed_dir)
        log.info(
            "native_hydro host finalize: committed %s via host-side validation",
            committed_dir.name,
        )


def _native_hydro_candidate_dirs(nodes_dir: Path, reserved_n: int) -> list[Path]:
    committed_prefix = f"v{reserved_n}_"
    staging_prefix = f".v{reserved_n}_"
    out: list[Path] = []
    for child in nodes_dir.iterdir():
        if not child.is_dir():
            continue
        if child.name.startswith(committed_prefix):
            out.append(child)
        elif child.name.startswith(staging_prefix) and child.name.endswith(".tmp"):
            out.append(child)
    return sorted(out, key=lambda p: p.name)


def _native_hydro_committed_name(candidate_dir: Path) -> str:
    name = candidate_dir.name
    if name.startswith(".") and name.endswith(".tmp"):
        return name[1:-4]
    return name


def _native_hydro_needs_host_validation(candidate_dir: Path, meta: dict) -> bool:
    reason = str(meta.get("failure_reason") or "").lower()
    if "pending host validation" in reason:
        return True
    if meta.get("attempt_status") != "OK":
        return True
    return not _native_hydro_reports_ok(candidate_dir)


def _native_hydro_reports_ok(candidate_dir: Path) -> bool:
    try:
        acc = json.loads((candidate_dir / "report_acc.json").read_text())
        perf = json.loads((candidate_dir / "report_perf.json").read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return False
    summary = acc.get("summary") or {}
    if summary.get("status") != "OK":
        return False
    if summary.get("total_nan_count", 0) or summary.get("total_inf_count", 0):
        return False
    if summary.get("drift_count", 0) or summary.get("fail_count", 0):
        return False
    if perf.get("status") != "OK":
        return False
    primary = next(
        (m for m in perf.get("measurements") or [] if m.get("shape") == "primary"),
        None,
    )
    mean = primary.get("mean_ms") if isinstance(primary, dict) else None
    return isinstance(mean, (int, float)) and math.isfinite(mean) and mean > 0


def _run_native_hydro_host_validation(
    *,
    task_dir: Path,
    node_arg: str,
    broker_sock: str,
    timeout_sec: float,
    validation_lines: list[str],
) -> tuple[bool, str]:
    try:
        acc = _submit_native_hydro_job(
            task_dir=task_dir,
            broker_sock=broker_sock,
            kind="test_acc",
            node_arg=node_arg,
            timeout_sec=timeout_sec,
        )
        validation_lines.append(_format_job_line("test_acc", acc))
        if not _job_ok(acc):
            return False, _format_failure_reason("test_acc", acc)

        perf = _submit_native_hydro_job(
            task_dir=task_dir,
            broker_sock=broker_sock,
            kind="test_perf",
            node_arg=node_arg,
            timeout_sec=timeout_sec,
        )
        validation_lines.append(_format_job_line("test_perf", perf))
        if not _job_ok(perf):
            return False, _format_failure_reason("test_perf", perf)
    except BrokerGone as e:
        msg = f"host validation broker unavailable: {e}"
        validation_lines.append(msg)
        return False, msg

    return True, ""


def _submit_native_hydro_job(
    *,
    task_dir: Path,
    broker_sock: str,
    kind: str,
    node_arg: str,
    timeout_sec: float,
) -> JobResponse:
    return submit(
        broker_sock,
        kind=kind,
        node_id=node_arg,
        task_dir=task_dir,
        client_timeout_sec=timeout_sec,
        heartbeat_path=Path(broker_sock).with_suffix(".heartbeat"),
    )


def _job_ok(resp: JobResponse) -> bool:
    return resp.status == "OK" and resp.returncode == 0


def _format_job_line(kind: str, resp: JobResponse) -> str:
    return (
        f"{kind}: status={resp.status} rc={resp.returncode} "
        f"queue_wait_ms={resp.queue_wait_ms} run_ms={resp.run_ms}"
    )


def _format_failure_reason(kind: str, resp: JobResponse) -> str:
    tail = (resp.stderr or resp.stdout or "").strip().splitlines()
    suffix = f"; tail: {tail[-1]}" if tail else ""
    return f"host validation {kind} failed status={resp.status} rc={resp.returncode}{suffix}"


def _append_host_validation_notes(notes_path: Path, validation_lines: list[str]) -> None:
    if not validation_lines:
        return
    try:
        existing = notes_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        existing = ""
    block = "\n".join(f"- {line}" for line in validation_lines)
    notes_path.write_text(
        existing.rstrip() + "\n\n## Host validation\n" + block + "\n",
        encoding="utf-8",
    )


def audit(task_dir: Path, reserved_n: int, node_dir: Path) -> list[str]:
    """§6.10 audit, reservation-scoped. Returns a list of violation strings."""
    errors: list[str] = []
    nodes_dir = task_dir / "nodes"

    # A1: exactly one v<reserved_n>_* committed dir; this one.
    matches = [
        c for c in nodes_dir.iterdir()
        if c.is_dir()
        and not c.name.startswith(".")
        and c.name.startswith(f"v{reserved_n}_")
    ]
    if len(matches) != 1:
        errors.append(
            f"A1: expected exactly one `v{reserved_n}_*` committed dir, found {len(matches)}: "
            f"{sorted(m.name for m in matches)}"
        )

    # A2: required files.
    if _task_mode(task_dir) == "native_hydro":
        required_files = ("kernel.cu", "meta.json", "notes.md")
    else:
        required_files = ("kernel.cu", "kernel.py", "meta.json", "notes.md")
    for rel in required_files:
        if not (node_dir / rel).is_file():
            errors.append(f"A2: {node_dir.name}/{rel} missing")

    notes_path = node_dir / "notes.md"
    if notes_path.is_file() and len(notes_path.read_text().strip()) < 80:
        errors.append(f"A2: {node_dir.name}/notes.md < 80 chars (stub)")

    # A3: meta.json parse + fields + node_id match.
    meta_path = node_dir / "meta.json"
    meta: dict = {}
    if meta_path.is_file():
        try:
            meta = json.loads(meta_path.read_text())
        except json.JSONDecodeError as e:
            errors.append(f"A3: {node_dir.name}/meta.json parse error: {e}")
            meta = {}
    for key in ("node_id", "parents", "action", "direction", "techniques", "attempt_status"):
        if key not in meta:
            errors.append(f"A3: meta.json missing field {key!r}")
    if meta.get("node_id") and meta["node_id"] != node_dir.name:
        errors.append(
            f"A3: meta.json node_id={meta['node_id']!r} disagrees with dir {node_dir.name!r}"
        )

    # A4: parents must be committed nodes (at audit time).
    committed_ids = {
        c.name for c in nodes_dir.iterdir()
        if c.is_dir() and not c.name.startswith(".") and c.name != node_dir.name
    }
    parents = meta.get("parents") or []
    if not isinstance(parents, list):
        errors.append("A4: meta.parents must be a list")
        parents = []
    for p in parents:
        if p not in committed_ids:
            errors.append(
                f"A4: parent {p!r} is not a committed node "
                f"(in-flight peers and non-existent ids are both invalid)"
            )

    # A5: action ↔ parent count.
    action = meta.get("action")
    if action == "mutate" and len(parents) != 1:
        errors.append(f"A5: action=mutate requires 1 parent, got {len(parents)}")
    elif action == "merge" and len(parents) < 2:
        errors.append(f"A5: action=merge requires >=2 parents, got {len(parents)}")
    elif action not in ("mutate", "merge"):
        errors.append(f"A5: action must be 'mutate' or 'merge', got {action!r}")

    status = meta.get("attempt_status")
    if status == "OK":
        # A6: report files + leaderboard row is Python's job; here we only
        # verify the reports exist and are parseable.
        errors.extend(_audit_ok_reports(node_dir))
    elif status == "FAIL":
        # A7: failure_reason non-empty.
        reason = meta.get("failure_reason")
        if not isinstance(reason, str) or not reason.strip():
            errors.append("A7: attempt_status=FAIL requires non-empty failure_reason")
    else:
        errors.append(f"A3: attempt_status must be 'OK' or 'FAIL', got {status!r}")

    # A8: no extra v<N>_* dirs (covered by A1 but lists explicitly).
    # — nothing to add; A1 already flagged.

    # A9: no residual .v<N>_*.tmp for our N.
    for child in nodes_dir.iterdir():
        if (
            child.is_dir()
            and child.name.startswith(f".v{reserved_n}_")
            and child.name.endswith(".tmp")
        ):
            errors.append(f"A9: residual staging dir {child.name} — rename incomplete")

    return errors


def _audit_ok_reports(node_dir: Path) -> list[str]:
    errors: list[str] = []
    acc_path = node_dir / "report_acc.json"
    perf_path = node_dir / "report_perf.json"
    if not acc_path.is_file():
        errors.append("A6: report_acc.json missing (required when attempt_status=OK)")
    else:
        try:
            acc = json.loads(acc_path.read_text())
            summary = acc.get("summary") or {}
            if summary.get("status") != "OK":
                errors.append(f"A6: report_acc summary.status={summary.get('status')!r}")
            if summary.get("total_nan_count", 0):
                errors.append(f"A6: report_acc total_nan_count={summary.get('total_nan_count')}")
            if summary.get("total_inf_count", 0):
                errors.append(f"A6: report_acc total_inf_count={summary.get('total_inf_count')}")
        except json.JSONDecodeError as e:
            errors.append(f"A6: report_acc parse error: {e}")

    if not perf_path.is_file():
        errors.append("A6: report_perf.json missing (required when attempt_status=OK)")
    else:
        try:
            perf = json.loads(perf_path.read_text())
            if perf.get("status") != "OK":
                errors.append(f"A6: report_perf status={perf.get('status')!r}")
            primary = next(
                (m for m in perf.get("measurements") or [] if m.get("shape") == "primary"),
                None,
            )
            if primary is None:
                errors.append("A6: report_perf no measurement for shape='primary'")
            else:
                mean = primary.get("mean_ms")
                if not isinstance(mean, (int, float)) or not math.isfinite(mean) or mean <= 0:
                    errors.append(f"A6: report_perf primary.mean_ms not positive finite: {mean!r}")
        except json.JSONDecodeError as e:
            errors.append(f"A6: report_perf parse error: {e}")
    return errors


# ----------------------------- main driver ------------------------------


def _drive_rounds(
    *,
    task_dir: Path,
    rounds: int,
    parallel: int,
    max_retries: int,
    model: str | None,
    worker_timeout_sec: float,
    reviewer_timeout_sec: float,
    log_dir: Path,
    worker_session_min_rounds: int,
    worker_session_max_rounds: int,
    rng_seed: int | None,
    reservation_timeout_sec: float,
    broker_proc: subprocess.Popen,
    on_round_done: Callable[[RoundReport], None] | None = None,
    slot_log_file: str | None = None,
) -> IterateReport:
    ctx = mp.get_context("spawn")
    work_q: mp.Queue = ctx.Queue()
    result_q: mp.Queue = ctx.Queue()

    cfg = _SlotConfig(
        task_dir=str(task_dir),
        log_dir=str(log_dir),
        broker_sock=str(task_dir / ".broker.sock"),
        max_retries=max_retries,
        model=model,
        worker_timeout_sec=worker_timeout_sec,
        reviewer_timeout_sec=reviewer_timeout_sec,
        worker_session_min_rounds=worker_session_min_rounds,
        worker_session_max_rounds=worker_session_max_rounds,
        base_seed=rng_seed,
        log_file=slot_log_file,
    )

    slot_ids = [f"s{i}" for i in range(parallel)]
    slots: dict[str, mp.Process] = {}
    for sid in slot_ids:
        p = ctx.Process(
            target=_slot_main,
            args=(sid, cfg, work_q, result_q),
            name=f"aker-slot-{sid}",
            daemon=False,
        )
        p.start()
        slots[sid] = p

    for rid in range(1, rounds + 1):
        work_q.put(rid)

    report = IterateReport()
    outstanding = rounds
    while outstanding > 0:
        # Check broker health.
        if broker_proc.poll() is not None:
            log.error("iterate: broker died mid-session (rc=%s); aborting", broker_proc.returncode)
            break
        # Pull a result with a short timeout to allow slot-death polling.
        try:
            rep: RoundReport = result_q.get(timeout=2.0)
            report.rounds.append(rep)
            outstanding -= 1
            log.info(
                "iterate: round %d slot=%s status=%s new_node=%s",
                rep.round_index, rep.slot_id, rep.status, rep.new_node_id,
            )
            if on_round_done is not None:
                try:
                    on_round_done(rep)
                except Exception:  # noqa: BLE001
                    log.exception("iterate: on_round_done callback raised")
        except _queue.Empty:
            # Poll slot liveness.
            dead_slots = [
                sid for sid, p in slots.items()
                if not p.is_alive() and p.exitcode is not None
            ]
            for sid in dead_slots:
                log.warning(
                    "iterate: slot %s died (exitcode=%s)",
                    sid, slots[sid].exitcode,
                )
                closed = close_all_open(
                    task_dir,
                    status=CLOSE_CRASHED,
                    reason="slot_crashed",
                    slot_id_filter=sid,
                )
                # Synthesize reports for any in-flight rounds that got lost.
                for r in closed:
                    fake = RoundReport(
                        round_index=-1,
                        slot_id=sid,
                        reservation_id=r.reservation_id,
                        reserved_n=r.reserved_n,
                        status="FAIL_SLOT_CRASH",
                        audit_errors=[f"slot {sid} died (exitcode={slots[sid].exitcode})"],
                    )
                    report.rounds.append(fake)
                    if on_round_done is not None:
                        try:
                            on_round_done(fake)
                        except Exception:  # noqa: BLE001
                            log.exception("iterate: on_round_done callback raised")
                    outstanding -= 1
                slots.pop(sid)
            if not slots:
                log.error("iterate: all slots died; aborting")
                break

    # Poison-pill surviving slots.
    for _ in range(len(slots)):
        work_q.put(POISON)
    for sid, p in slots.items():
        p.join(timeout=30)
        if p.is_alive():
            log.warning("iterate: slot %s did not exit after poison pill; terminating", sid)
            p.terminate()
            p.join(timeout=5)

    return report
