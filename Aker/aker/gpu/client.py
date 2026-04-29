"""Client-side of the GPU broker protocol.

Used by `akerjob` (see `aker/gpu/worker_cli.py`) and by any other in-
process caller that needs to submit a GPU job to the broker. Blocking:
one request, one response, socket-scoped `settimeout` so the caller can
surface "broker gone" as a distinct failure.

See dev/parallel.md §6.1 (protocol), §6.2 (env contract), §6.11 (crash
detection via socket.settimeout + heartbeat poll).
"""

from __future__ import annotations

import json
import os
import socket
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

EXIT_BROKER_GONE = 97
HEARTBEAT_STALE_SEC = 15.0


class BrokerGone(RuntimeError):
    """Raised when the broker is unreachable or has stopped responding."""


@dataclass
class JobResponse:
    job_id: str | None
    status: str
    queue_wait_ms: int | None
    run_ms: int | None
    stdout: str
    stderr: str
    returncode: int | None
    raw: dict[str, Any]


def submit(
    sock_path: Path | str,
    *,
    kind: str,
    node_id: str,
    task_dir: Path | str,
    extra_args: list[str] | None = None,
    client_timeout_sec: float = 1800.0,
    heartbeat_path: Path | str | None = None,
) -> JobResponse:
    """Submit a job to the broker at `sock_path` and wait for the response.

    Raises BrokerGone if the socket closes unexpectedly or if the recv
    times out AND the broker heartbeat is stale (i.e., the broker really
    did die, not just slow).
    """
    extra_args = list(extra_args or [])
    req = {
        "kind": kind,
        "node_id": node_id,
        "task_dir": str(Path(task_dir).resolve()),
        "extra_args": extra_args,
        "client_timeout_sec": client_timeout_sec,
    }
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    # +60 covers queue wait, shutdown drain, and response send time.
    sock.settimeout(client_timeout_sec + 60.0)
    try:
        try:
            sock.connect(str(sock_path))
        except (FileNotFoundError, ConnectionRefusedError) as e:
            raise BrokerGone(f"broker socket unreachable: {e}") from e
        sock.sendall((json.dumps(req) + "\n").encode("utf-8"))
        payload = _recv_response(sock, heartbeat_path=heartbeat_path)
    except (BrokenPipeError, ConnectionResetError, EOFError) as e:
        raise BrokerGone(f"broker closed connection: {e}") from e
    finally:
        try:
            sock.close()
        except Exception:
            pass

    return JobResponse(
        job_id=payload.get("job_id"),
        status=payload.get("status", "BROKER_ERROR"),
        queue_wait_ms=payload.get("queue_wait_ms"),
        run_ms=payload.get("run_ms"),
        stdout=payload.get("stdout", "") or "",
        stderr=payload.get("stderr", "") or "",
        returncode=payload.get("returncode"),
        raw=payload,
    )


def _recv_response(
    sock: socket.socket,
    *,
    heartbeat_path: Path | str | None,
) -> dict[str, Any]:
    buf = bytearray()
    while True:
        try:
            chunk = sock.recv(65536)
        except socket.timeout as e:
            if _heartbeat_is_stale(heartbeat_path):
                raise BrokerGone(
                    "broker heartbeat stale (>15s) while client was blocked on recv"
                ) from e
            # Broker might genuinely be slow — keep waiting one more cycle.
            raise BrokerGone(f"socket.timeout: {e}") from e
        if not chunk:
            break
        buf.extend(chunk)
        if b"\n" in chunk:
            break
    if not buf:
        raise BrokerGone("broker closed socket with no response")
    return json.loads(bytes(buf).decode("utf-8").rstrip("\n"))


def _heartbeat_is_stale(heartbeat_path: Path | str | None) -> bool:
    if heartbeat_path is None:
        return False
    try:
        mtime = os.path.getmtime(str(heartbeat_path))
    except OSError:
        return True
    return (time.time() - mtime) > HEARTBEAT_STALE_SEC
