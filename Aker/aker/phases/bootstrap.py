"""Bootstrap phase — drive the worker+reviewer loop and audit v0 outputs.

Public entry point: `run(task_dir, ...) -> BootstrapReport`. The task
dir must already contain `spec.md` (produced by the spec phase). On
success, the v0 node (`nodes/v0_naive_cuda/…`) and shared test infra
(`testlib.py`, `test_acc.py`, `test_perf.py`) are all present and pass
contract checks.

Under the parallel design (dev/parallel.md §6), bootstrap also:
- spawns the broker for its single round (v0 is one round)
- injects `AKER_BROKER_SOCK` / `AKER_TASK_DIR` / `CUDA_VISIBLE_DEVICES=""`
  into the codex subprocess so the LLM reaches the GPU only through
  `akerjob` (P17)
- writes `leaderboard.jsonl` / `leaderboard.md` itself (Python-owned,
  §6.12.1) after audit passes — the worker no longer does.
"""

from __future__ import annotations

import atexit
import fcntl
import json
import logging
import math
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

from aker.infra.backend import SANDBOX_DANGER_FULL_ACCESS, make_session
from aker.state.graph import backfill_v0_meta
from aker.state.leaderboard import LeaderboardError, commit_row, regenerate_md
from aker.phases.review_loop import (
    ReviewLoopResult,
    ReviewPrompts,
    run_review_loop,
)

log = logging.getLogger(__name__)

PROMPT_DIR = Path(__file__).parent.parent / "prompts"

V0_NODE_DIR = "nodes/v0_naive_cuda"

EXPECTED_FILES: tuple[str, ...] = (
    "testlib.py",
    "test_acc.py",
    "test_perf.py",
    f"{V0_NODE_DIR}/kernel.cu",
    f"{V0_NODE_DIR}/kernel.py",
    f"{V0_NODE_DIR}/meta.json",
    f"{V0_NODE_DIR}/notes.md",
    f"{V0_NODE_DIR}/report_acc.json",
    f"{V0_NODE_DIR}/report_perf.json",
)


@dataclass
class BootstrapReport:
    """Structured result of a single bootstrap invocation.

    `status` is one of:
      - "OK"           — review PASS and on-disk audit clean
      - "FAIL_REVIEW"  — review loop did not reach PASS
      - "FAIL_AUDIT"   — review PASSed but the on-disk state is still
                         inconsistent with the bootstrap contract
    """

    status: str
    review: ReviewLoopResult
    missing_files: list[str] = field(default_factory=list)
    audit_errors: list[str] = field(default_factory=list)
    leaderboard_row: dict | None = None
    acc_summary: dict | None = None
    perf_primary: dict | None = None

    @property
    def ok(self) -> bool:
        return self.status == "OK"


def load_prompts() -> ReviewPrompts:
    """Read the four bootstrap-phase prompts from `aker/prompts/`."""
    return ReviewPrompts(
        worker_initial=(PROMPT_DIR / "bootstrap_worker.md").read_text(),
        reviewer_initial=(PROMPT_DIR / "bootstrap_reviewer.md").read_text(),
        worker_fix_template=(PROMPT_DIR / "bootstrap_worker_fix.md").read_text(),
        reviewer_recheck_template=(
            PROMPT_DIR / "bootstrap_reviewer_recheck.md"
        ).read_text(),
    )


def run(
    task_dir: Path | str,
    *,
    max_retries: int = 3,
    log_path: Path | str | None = None,
    model: str | None = None,
    worker_timeout_sec: float = 3600.0,
    reviewer_timeout_sec: float = 3600.0,
) -> BootstrapReport:
    """Run bootstrap on `task_dir`, then audit the outputs.

    Raises `FileNotFoundError` if `spec.md` does not exist in the task
    directory (the spec phase must run first).

    Spawns a broker for the duration of the call (bootstrap is a single
    round) and injects `AKER_BROKER_SOCK` / `AKER_TASK_DIR` /
    `CUDA_VISIBLE_DEVICES=""` into the codex subprocess environment.
    """
    task_dir = Path(task_dir).resolve()
    if not (task_dir / "spec.md").exists():
        raise FileNotFoundError(f"spec.md not found in {task_dir}")

    device_lock_fd = _acquire_device_lock()
    broker_proc = _spawn_broker(task_dir)

    def _cleanup() -> None:
        _terminate_broker(broker_proc)
        try:
            os.close(device_lock_fd)
        except OSError:
            pass

    atexit.register(_cleanup)

    try:
        prompts = load_prompts()
        worker = make_session(
            cwd=task_dir,
            sandbox=SANDBOX_DANGER_FULL_ACCESS,
            timeout_sec=worker_timeout_sec,
            model=model,
            extra_env={
                "AKER_BROKER_SOCK": str(task_dir / ".broker.sock"),
                "AKER_TASK_DIR": str(task_dir),
                "CUDA_VISIBLE_DEVICES": "",
            },
        )
        review = run_review_loop(
            task_dir=task_dir,
            prompts=prompts,
            max_retries=max_retries,
            log_path=log_path,
            model=model,
            worker_timeout_sec=worker_timeout_sec,
            reviewer_timeout_sec=reviewer_timeout_sec,
            worker=worker,
        )

        if review.status != "OK":
            return BootstrapReport(status="FAIL_REVIEW", review=review)

        missing, errors = audit(task_dir)
        if not missing and not errors:
            # Bootstrap prompt's v0 meta.json schema omits `attempt_status`
            # (it's implicitly OK once tests pass). Backfill the iterate-era
            # fields before commit_row, which keys off attempt_status=="OK".
            backfill_v0_meta(task_dir)
            try:
                commit_row(task_dir, "v0_naive_cuda")
            except LeaderboardError as e:
                errors.append(f"leaderboard commit: {e}")
            except Exception as e:  # noqa: BLE001
                log.exception("bootstrap: leaderboard commit failed")
                errors.append(f"leaderboard unexpected: {type(e).__name__}: {e}")

        lb_row = _read_leaderboard_row(task_dir)
        acc_summary = _read_acc_summary(task_dir)
        perf_primary = _read_perf_primary(task_dir)

        status = "OK" if not missing and not errors else "FAIL_AUDIT"
        return BootstrapReport(
            status=status,
            review=review,
            missing_files=missing,
            audit_errors=errors,
            leaderboard_row=lb_row,
            acc_summary=acc_summary,
            perf_primary=perf_primary,
        )
    finally:
        _cleanup()
        try:
            atexit.unregister(_cleanup)
        except Exception:
            pass


def audit(task_dir: Path | str) -> tuple[list[str], list[str]]:
    """Check that the bootstrap contract holds on disk.

    Returns `(missing_files, errors)`. `missing_files` lists expected
    paths that do not exist (pre-leaderboard — leaderboard is Python's
    responsibility to create, checked separately). `errors` lists
    content-level violations (e.g. non-positive runtime, non-zero NaN
    count).
    """
    task_dir = Path(task_dir).resolve()

    missing = [rel for rel in EXPECTED_FILES if not (task_dir / rel).exists()]
    errors: list[str] = []
    if missing:
        return missing, errors

    _audit_report_acc(task_dir, errors)
    _audit_report_perf(task_dir, errors)
    _audit_meta(task_dir, errors)
    return missing, errors


def _audit_report_acc(task_dir: Path, errors: list[str]) -> None:
    acc = json.loads((task_dir / f"{V0_NODE_DIR}/report_acc.json").read_text())
    summary = acc.get("summary")
    if not isinstance(summary, dict):
        errors.append("report_acc.json summary is missing or not an object")
        return
    if summary.get("status") != "OK":
        errors.append(
            f"report_acc.summary.status={summary.get('status')!r}, expected 'OK'"
        )
    nan_count = summary.get("total_nan_count", 0)
    inf_count = summary.get("total_inf_count", 0)
    if nan_count:
        errors.append(f"report_acc.summary.total_nan_count={nan_count}")
    if inf_count:
        errors.append(f"report_acc.summary.total_inf_count={inf_count}")


def _audit_report_perf(task_dir: Path, errors: list[str]) -> None:
    perf = json.loads((task_dir / f"{V0_NODE_DIR}/report_perf.json").read_text())
    if perf.get("status") != "OK":
        errors.append(
            f"report_perf.status={perf.get('status')!r}, expected 'OK'"
        )
    primary = next(
        (m for m in perf.get("measurements", []) if m.get("shape") == "primary"),
        None,
    )
    if primary is None:
        errors.append("report_perf.measurements has no entry for shape='primary'")
        return
    mean_ms = primary.get("mean_ms")
    if not isinstance(mean_ms, (int, float)) or not math.isfinite(mean_ms) or mean_ms <= 0:
        errors.append(
            f"report_perf.primary.mean_ms is not a positive finite number: {mean_ms!r}"
        )


def _audit_meta(task_dir: Path, errors: list[str]) -> None:
    meta = json.loads((task_dir / f"{V0_NODE_DIR}/meta.json").read_text())
    # v0 meta may not have attempt_status in older bootstrap; inject on read.
    if meta.get("node_id") != "v0_naive_cuda":
        errors.append(f"meta.json node_id={meta.get('node_id')!r}, expected 'v0_naive_cuda'")


def _read_leaderboard_row(task_dir: Path) -> dict | None:
    path = task_dir / "leaderboard.jsonl"
    if not path.is_file():
        return None
    lines = [ln for ln in path.read_text().splitlines() if ln.strip()]
    if not lines:
        return None
    try:
        return json.loads(lines[-1])
    except json.JSONDecodeError:
        return None


def _read_acc_summary(task_dir: Path) -> dict | None:
    path = task_dir / f"{V0_NODE_DIR}/report_acc.json"
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text()).get("summary")
    except json.JSONDecodeError:
        return None


def _read_perf_primary(task_dir: Path) -> dict | None:
    path = task_dir / f"{V0_NODE_DIR}/report_perf.json"
    if not path.is_file():
        return None
    try:
        perf = json.loads(path.read_text())
    except json.JSONDecodeError:
        return None
    for m in perf.get("measurements") or []:
        if m.get("shape") == "primary":
            return m
    return None


# ----------------------------- device lock / broker ---------------------
# Duplicated from iterate.py (kept separate so bootstrap can be imported
# standalone without the iterate module). Both call sites share semantics.


def _acquire_device_lock() -> int:
    import hashlib
    raw = os.environ.get("CUDA_VISIBLE_DEVICES", "0")
    parts = sorted(p.strip() for p in raw.split(",") if p.strip())
    norm = "-".join(parts) if parts else "0"
    if len(norm) > 32:
        norm = hashlib.sha1(norm.encode()).hexdigest()[:16]
    path = f"/tmp/aker_gpu_{norm}.lock"
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        try:
            os.lseek(fd, 0, os.SEEK_SET)
            prev_pid = int(os.read(fd, 64).decode(errors="replace").strip())
            os.kill(prev_pid, 0)
            os.close(fd)
            sys.exit(
                f"GPU device {raw!r} already managed by aker run PID {prev_pid}"
            )
        except (ValueError, ProcessLookupError):
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    os.lseek(fd, 0, os.SEEK_SET)
    os.ftruncate(fd, 0)
    os.write(fd, f"{os.getpid()}\n".encode())
    os.fsync(fd)
    return fd


def _spawn_broker(task_dir: Path) -> subprocess.Popen:
    sock_path = task_dir / ".broker.sock"
    try:
        sock_path.unlink()
    except FileNotFoundError:
        pass
    proc = subprocess.Popen(
        [sys.executable, "-m", "aker.gpu.broker", str(task_dir)],
        env=os.environ.copy(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
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


def _terminate_broker(proc: subprocess.Popen) -> None:
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
        log.exception("bootstrap: broker termination error")
