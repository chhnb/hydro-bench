"""GPU broker: serializes GPU access for parallel workers in `aker run`.

Runs as a child process of `aker run` (see dev/parallel.md §6.1). Listens
on a unix socket at `task_dir/.broker.sock`. Workers — via the `akerjob`
CLI inside their codex sandbox — submit JSON job requests; the broker
runs them one at a time in a subprocess, enforcing per-kind timeouts, and
returns the result on the same connection.

Job kinds supported in v1:

- `test_acc`      — runs `python test_acc.py --version <node_id>`
- `test_perf`     — runs `python test_perf.py --version <node_id>`
- `profile_ncu`   — stub; returns NOT_IMPLEMENTED

SASS disassembly is intentionally NOT a broker job kind — `cuobjdump`
is a pure static tool, no GPU lock needed; workers run it directly.

The broker is the **sole holder of GPU access** in the system (P1). Under
v1 it uses compile path (a) from §6.9: the test subprocess is the thing
that imports the kernel and calls `torch.utils.cpp_extension.load()`, so
CUDA context init + measurement happen together, serialized by the FIFO.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import queue as _queue
import signal
import socket
import subprocess
import sys
import threading
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any

log = logging.getLogger(__name__)

def _default_timeouts() -> dict[str, float]:
    return {
        "test_acc": float(os.environ.get("AKER_TEST_ACC_TIMEOUT_SEC", "1800")),
        "test_perf": float(os.environ.get("AKER_TEST_PERF_TIMEOUT_SEC", "1800")),
        "profile_ncu": float(os.environ.get("AKER_PROFILE_NCU_TIMEOUT_SEC", "900")),
    }

# SASS disassembly is NOT brokered. `cuobjdump --dump-sass <.so>` is a
# pure static tool that reads the compiled ELF and never touches the
# device — it does not need the FIFO lock. Workers run it directly in
# their sandbox. Only tools that actually use the GPU (test_acc,
# test_perf, NCU profiling) go through the broker.

HEARTBEAT_INTERVAL_SEC = 5.0
SIGTERM_GRACE_SEC = 10.0
RECV_CHUNK = 65536


@dataclass
class _Job:
    kind: str
    node_id: str
    task_dir: str
    extra_args: list[str]
    client_timeout_sec: float
    job_id: str
    enqueued_at: float
    conn: socket.socket


def run_broker(
    task_dir: Path | str,
    *,
    sock_path: Path | str | None = None,
    heartbeat_path: Path | str | None = None,
    jobs_log_path: Path | str | None = None,
    timeouts: dict[str, float] | None = None,
) -> None:
    """Run a broker in the current process until SIGTERM/SIGINT."""
    task_dir = Path(task_dir).resolve()
    sock_path = Path(sock_path or task_dir / ".broker.sock")
    heartbeat_path = Path(heartbeat_path or task_dir / ".broker.heartbeat")
    jobs_log_path = Path(jobs_log_path or task_dir / "_gpu_jobs.jsonl")
    timeouts = {**_default_timeouts(), **(timeouts or {})}

    if sock_path.exists():
        sock_path.unlink()

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(sock_path))
    server.listen(16)
    os.chmod(sock_path, 0o600)

    job_queue: "_queue.Queue[_Job]" = _queue.Queue()
    shutting_down = threading.Event()

    hb_stop = threading.Event()

    def _heartbeat() -> None:
        while not hb_stop.is_set():
            try:
                heartbeat_path.touch(exist_ok=True)
                os.utime(heartbeat_path, None)
            except Exception:
                log.exception("broker heartbeat failed")
            hb_stop.wait(HEARTBEAT_INTERVAL_SEC)

    hb_thread = threading.Thread(target=_heartbeat, daemon=True, name="broker-hb")
    hb_thread.start()

    def _runner() -> None:
        while not shutting_down.is_set():
            try:
                job = job_queue.get(timeout=0.25)
            except _queue.Empty:
                continue
            _execute(job, timeouts, jobs_log_path)

    runner = threading.Thread(target=_runner, daemon=True, name="broker-runner")
    runner.start()

    def _shutdown(_signo: int, _frame: Any) -> None:
        shutting_down.set()
        try:
            server.close()
        except Exception:
            pass

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT, _shutdown)

    log.info("broker listening at %s", sock_path)
    while not shutting_down.is_set():
        try:
            conn, _ = server.accept()
        except OSError:
            break
        try:
            payload = _recv_until_newline(conn)
            req = json.loads(payload)
            job = _Job(
                kind=str(req["kind"]),
                node_id=str(req["node_id"]),
                task_dir=str(req.get("task_dir") or task_dir),
                extra_args=list(req.get("extra_args") or []),
                client_timeout_sec=float(
                    req.get("client_timeout_sec") or timeouts.get(req["kind"], 600.0)
                ),
                job_id=f"job-{uuid.uuid4().hex[:10]}",
                enqueued_at=time.monotonic(),
                conn=conn,
            )
            job_queue.put(job)
        except Exception as e:
            log.exception("broker: bad request")
            try:
                _send(conn, {"status": "BROKER_ERROR", "error": str(e)})
            finally:
                try:
                    conn.close()
                except Exception:
                    pass

    hb_stop.set()
    try:
        sock_path.unlink()
    except FileNotFoundError:
        pass
    log.info("broker exiting")


def _execute(job: _Job, timeouts: dict[str, float], jobs_log_path: Path) -> None:
    queue_wait_ms = int((time.monotonic() - job.enqueued_at) * 1000)
    started = time.monotonic()

    # Broker's server-side timeout is the tighter of (per-kind default)
    # and (client's explicit budget). Client budget is authoritative: if
    # the client is only willing to wait 5s, killing the subprocess at 5s
    # is honest — the alternative is us burning CPU on a job nobody will
    # read the result of.
    timeout = min(timeouts.get(job.kind, 600.0), max(job.client_timeout_sec, 1.0))

    cmd = _build_cmd(job)
    if cmd is None:
        _respond_and_log(
            job,
            jobs_log_path,
            {
                "job_id": job.job_id,
                "status": "NOT_IMPLEMENTED",
                "queue_wait_ms": queue_wait_ms,
                "run_ms": 0,
                "stdout": "",
                "stderr": f"broker: job kind {job.kind!r} is not implemented in v1\n",
                "returncode": None,
            },
        )
        return

    stdout = stderr = b""
    status = "OK"
    rc: int | None = None
    try:
        proc = subprocess.Popen(
            cmd,
            cwd=job.task_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=_subprocess_env(),
            start_new_session=True,
        )
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
            rc = proc.returncode
            status = "OK" if rc == 0 else "SUBPROCESS_NONZERO"
        except subprocess.TimeoutExpired:
            status = "TIMEOUT"
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                stdout, stderr = proc.communicate(timeout=SIGTERM_GRACE_SEC)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                stdout, stderr = proc.communicate()
            rc = proc.returncode
    except FileNotFoundError as e:
        status = "BROKER_ERROR"
        stderr = f"broker: command not found: {e}\n".encode()
    except Exception as e:  # noqa: BLE001
        log.exception("broker: subprocess failure")
        status = "BROKER_ERROR"
        stderr = f"broker: {type(e).__name__}: {e}\n".encode()

    run_ms = int((time.monotonic() - started) * 1000)
    response = {
        "job_id": job.job_id,
        "status": status,
        "queue_wait_ms": queue_wait_ms,
        "run_ms": run_ms,
        "stdout": stdout.decode("utf-8", errors="replace") if stdout else "",
        "stderr": stderr.decode("utf-8", errors="replace") if stderr else "",
        "returncode": rc,
    }
    _respond_and_log(job, jobs_log_path, response)


def _build_cmd(job: _Job) -> list[str] | None:
    if job.kind == "test_acc":
        return [sys.executable, "test_acc.py", "--version", job.node_id, *job.extra_args]
    if job.kind == "test_perf":
        return [sys.executable, "test_perf.py", "--version", job.node_id, *job.extra_args]
    if job.kind == "profile_ncu":
        return None
    return None


def _subprocess_env() -> dict[str, str]:
    # The broker inherits the real CUDA_VISIBLE_DEVICES from `aker run`.
    # Codex sandboxes have it set to "" (P17). Subprocesses here need the
    # real value so test_perf.py can touch the GPU. No override needed —
    # os.environ already has what we want.
    return os.environ.copy()


def _respond_and_log(job: _Job, jobs_log_path: Path, response: dict[str, Any]) -> None:
    try:
        _send(job.conn, response)
    except (BrokenPipeError, ConnectionResetError, OSError):
        log.warning("broker: client gone before response for job %s", job.job_id)
    finally:
        try:
            job.conn.close()
        except Exception:
            pass
    _append_jobs_log(
        jobs_log_path,
        {
            "job_id": job.job_id,
            "kind": job.kind,
            "node_id": job.node_id,
            "status": response["status"],
            "queue_wait_ms": response["queue_wait_ms"],
            "run_ms": response["run_ms"],
            "ts": time.time(),
        },
    )


def _append_jobs_log(path: Path, row: dict[str, Any]) -> None:
    # best-effort, no fsync (dev/parallel.md §6.1 bullet 5)
    try:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(row) + "\n")
    except OSError:
        log.exception("broker: failed to append %s", path)


def _recv_until_newline(conn: socket.socket) -> str:
    buf = bytearray()
    while True:
        chunk = conn.recv(RECV_CHUNK)
        if not chunk:
            break
        buf.extend(chunk)
        if b"\n" in chunk:
            break
    return bytes(buf).decode("utf-8").rstrip("\n")


def _send(conn: socket.socket, payload: dict[str, Any]) -> None:
    data = (json.dumps(payload) + "\n").encode("utf-8")
    conn.sendall(data)


def _cli() -> int:
    parser = argparse.ArgumentParser(
        prog="python -m aker.gpu.broker",
        description="Run a GPU broker for a task directory (foreground).",
    )
    parser.add_argument("task_dir")
    args = parser.parse_args()
    logging.basicConfig(
        level=os.environ.get("AKER_BROKER_LOG", "INFO").upper(),
        format="%(asctime)s broker %(levelname)s %(message)s",
    )
    run_broker(args.task_dir)
    return 0


if __name__ == "__main__":
    sys.exit(_cli())
