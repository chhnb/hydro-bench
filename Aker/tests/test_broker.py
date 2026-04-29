"""Standalone smoke for the GPU broker.

Exercises:

- Broker spawn via `python -m aker.gpu.broker <task_dir>`.
- akerjob → broker → real subprocess round-trip (with a trivial
  `test_acc.py` that writes a known string).
- FIFO ordering (two concurrent submissions serialized).
- Timeout kill path (broker kills a runaway subprocess).
- NOT_IMPLEMENTED stub kind returns cleanly.
- Client-side `BrokerGone` when the socket vanishes mid-wait.

Run directly:

    python tests/test_broker.py
"""

from __future__ import annotations

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from aker.gpu.client import BrokerGone, submit  # noqa: E402


def _subprocess_env(**overrides: str) -> dict[str, str]:
    env = os.environ.copy()
    old = env.get("PYTHONPATH")
    env["PYTHONPATH"] = str(ROOT) if not old else str(ROOT) + os.pathsep + old
    env.update(overrides)
    return env


def _spawn_broker(task_dir: Path) -> subprocess.Popen:
    proc = subprocess.Popen(
        [sys.executable, "-m", "aker.gpu.broker", str(task_dir)],
        env=_subprocess_env(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    deadline = time.monotonic() + 10.0
    sock = task_dir / ".broker.sock"
    while time.monotonic() < deadline:
        if sock.exists():
            return proc
        if proc.poll() is not None:
            raise RuntimeError(
                "broker died: " + (proc.stderr.read() or b"").decode(errors="replace")
            )
        time.sleep(0.05)
    raise RuntimeError("broker socket did not appear")


def _write_fake_test_scripts(task_dir: Path) -> None:
    (task_dir / "test_acc.py").write_text(
        'import sys; print("acc", *sys.argv[1:]); sys.exit(0)\n'
    )
    (task_dir / "test_perf.py").write_text(
        """import sys, time
args = sys.argv
# Honor a SLEEP_SEC env for timeout testing.
import os
t = float(os.environ.get("SLEEP_SEC", 0))
time.sleep(t)
print("perf", *args[1:])
sys.exit(0)
""".lstrip()
    )


def test_roundtrip(task_dir: Path) -> None:
    _write_fake_test_scripts(task_dir)
    proc = _spawn_broker(task_dir)
    try:
        sock = task_dir / ".broker.sock"
        resp = submit(
            sock, kind="test_acc", node_id="vX_fake",
            task_dir=task_dir, client_timeout_sec=30,
            heartbeat_path=task_dir / ".broker.heartbeat",
        )
        assert resp.status == "OK", f"got {resp.status} stderr={resp.stderr}"
        assert "acc --version vX_fake" in resp.stdout, resp.stdout
        assert resp.run_ms is not None and resp.run_ms >= 0
        print(f"[roundtrip] OK stdout={resp.stdout.strip()!r}")
    finally:
        proc.terminate()
        proc.wait(timeout=3)


def test_fifo_ordering(task_dir: Path) -> None:
    # Two clients hit the broker at once; the broker serializes them. We
    # verify both complete and that the log reflects sequential run_ms.
    _write_fake_test_scripts(task_dir)
    proc = subprocess.Popen(
        [sys.executable, "-m", "aker.gpu.broker", str(task_dir)],
        env=_subprocess_env(SLEEP_SEC="0.3"),  # each job sleeps 300ms
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    try:
        sock = task_dir / ".broker.sock"
        deadline = time.monotonic() + 10.0
        while time.monotonic() < deadline and not sock.exists():
            time.sleep(0.05)
        results: dict[str, object] = {}

        def _call(tag: str) -> None:
            try:
                results[tag] = submit(
                    sock, kind="test_perf", node_id=f"v{tag}_x",
                    task_dir=task_dir, client_timeout_sec=30,
                )
            except Exception as e:
                results[tag] = e

        t1 = threading.Thread(target=_call, args=("1",))
        t2 = threading.Thread(target=_call, args=("2",))
        t1.start(); time.sleep(0.05); t2.start()
        t1.join(); t2.join()

        for tag in ("1", "2"):
            r = results[tag]
            assert not isinstance(r, Exception), r
            assert r.status == "OK", r.status  # type: ignore[union-attr]
        # Second job's queue_wait_ms should be >= first job's run_ms minus slack.
        # Hard to order deterministically without order tracking, but at least
        # one of the two saw a non-zero queue wait.
        waits = [r.queue_wait_ms for r in results.values()]  # type: ignore[union-attr]
        assert max(waits) >= 100, f"expected one job to queue; waits={waits}"
        print(f"[fifo ] OK queue_waits={waits}")
    finally:
        proc.terminate()
        proc.wait(timeout=3)


def test_timeout_kill(task_dir: Path) -> None:
    _write_fake_test_scripts(task_dir)
    # test_perf sleeps 5s; broker will kill it at 2s because client budget
    # caps the server-side timeout.
    proc = subprocess.Popen(
        [sys.executable, "-m", "aker.gpu.broker", str(task_dir)],
        env=_subprocess_env(SLEEP_SEC="5.0"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    try:
        sock = task_dir / ".broker.sock"
        deadline = time.monotonic() + 10.0
        while time.monotonic() < deadline and not sock.exists():
            time.sleep(0.05)
        t0 = time.monotonic()
        resp = submit(
            sock, kind="test_perf", node_id="vT_to",
            task_dir=task_dir, client_timeout_sec=2.0,
        )
        dt = time.monotonic() - t0
        assert resp.status == "TIMEOUT", f"expected TIMEOUT got {resp.status}"
        assert dt < 20, f"timeout took too long ({dt:.1f}s)"
        print(f"[timeout] OK took {dt:.1f}s")
    finally:
        proc.terminate()
        proc.wait(timeout=3)


def test_not_implemented(task_dir: Path) -> None:
    proc = _spawn_broker(task_dir)
    try:
        sock = task_dir / ".broker.sock"
        resp = submit(
            sock, kind="profile_ncu", node_id="vZ_fake",
            task_dir=task_dir, client_timeout_sec=10,
        )
        assert resp.status == "NOT_IMPLEMENTED", resp.status
        print(f"[ni   ] OK stderr={resp.stderr.strip()!r}")
    finally:
        proc.terminate()
        proc.wait(timeout=3)


def test_subprocess_nonzero(task_dir: Path) -> None:
    """Fake test script exits non-zero → broker returns SUBPROCESS_NONZERO
    with the real returncode."""
    # Script that exits 3 regardless of args.
    (task_dir / "test_acc.py").write_text(
        "import sys; sys.stderr.write('fake failure\\n'); sys.exit(3)\n"
    )
    proc = _spawn_broker(task_dir)
    try:
        sock = task_dir / ".broker.sock"
        resp = submit(
            sock, kind="test_acc", node_id="vNZ_fake",
            task_dir=task_dir, client_timeout_sec=10,
        )
        assert resp.status == "SUBPROCESS_NONZERO", f"got {resp.status}"
        assert resp.returncode == 3, f"expected rc=3, got {resp.returncode}"
        assert "fake failure" in resp.stderr, resp.stderr
        print(f"[nonzero] OK returncode={resp.returncode}")
    finally:
        proc.terminate()
        proc.wait(timeout=3)


def test_broker_gone_killed_midrecv(task_dir: Path) -> None:
    """Live socket + pending job + broker killed → client sees BrokerGone.

    This differs from `test_broker_gone` (where the socket never existed).
    Here the client has connected, sent a request, and is blocked in
    recv when the broker is SIGKILLed.
    """
    # Fake test_acc that sleeps 30s so the broker's subprocess is still
    # running when we kill the broker.
    (task_dir / "test_acc.py").write_text(
        "import time; time.sleep(30)\n"
    )
    proc = _spawn_broker(task_dir)
    sock = task_dir / ".broker.sock"

    err: dict[str, object] = {"val": None}

    def _do_submit() -> None:
        try:
            submit(
                sock, kind="test_acc", node_id="vKM_fake",
                task_dir=task_dir, client_timeout_sec=20,
            )
            err["val"] = AssertionError("expected BrokerGone, got OK")
        except BrokerGone:
            err["val"] = None
        except Exception as e:  # noqa: BLE001
            err["val"] = e

    t = threading.Thread(target=_do_submit)
    t.start()
    # Give the client time to connect + send the request so broker
    # actually starts the subprocess before we kill it.
    time.sleep(0.5)
    proc.kill()
    proc.wait(timeout=3)
    t.join(timeout=15)
    assert not t.is_alive(), "submit did not return after broker killed"
    assert err["val"] is None, f"unexpected outcome: {err['val']!r}"
    print("[killed] OK BrokerGone raised after mid-recv kill")


def test_heartbeat_stale_helper(task_dir: Path) -> None:
    """Unit-test the client-side staleness check directly. We don't need
    a broker for this — it's just file mtime arithmetic."""
    from aker.gpu.client import _heartbeat_is_stale, HEARTBEAT_STALE_SEC
    hb = task_dir / ".broker.heartbeat"
    # Missing file → stale.
    assert _heartbeat_is_stale(hb) is True
    hb.touch()
    # Freshly touched → not stale.
    assert _heartbeat_is_stale(hb) is False
    # Age it past the threshold.
    ancient = time.time() - (HEARTBEAT_STALE_SEC + 5.0)
    os.utime(hb, (ancient, ancient))
    assert _heartbeat_is_stale(hb) is True
    print("[hb    ] OK heartbeat staleness reflects file mtime")


def test_broker_gone(task_dir: Path) -> None:
    # Spawn, kill, then try to submit → expect BrokerGone.
    proc = _spawn_broker(task_dir)
    proc.terminate()
    proc.wait(timeout=3)
    # Also delete any leftover socket to ensure we hit unreachable.
    try:
        (task_dir / ".broker.sock").unlink()
    except FileNotFoundError:
        pass
    try:
        submit(
            task_dir / ".broker.sock",
            kind="test_acc", node_id="vG_gone",
            task_dir=task_dir, client_timeout_sec=5,
        )
    except BrokerGone:
        print("[gone ] OK BrokerGone raised")
        return
    raise AssertionError("expected BrokerGone")


def main() -> int:
    names = ("roundtrip", "fifo", "timeout", "ni", "nonzero", "killed", "hb", "gone")
    with tempfile.TemporaryDirectory(prefix="aker_broker_test_") as td_str:
        roots = {}
        for name in names:
            td = Path(td_str) / name
            td.mkdir()
            roots[name] = td
        test_roundtrip(roots["roundtrip"])
        test_fifo_ordering(roots["fifo"])
        test_timeout_kill(roots["timeout"])
        test_not_implemented(roots["ni"])
        test_subprocess_nonzero(roots["nonzero"])
        test_broker_gone_killed_midrecv(roots["killed"])
        test_heartbeat_stale_helper(roots["hb"])
        test_broker_gone(roots["gone"])
    print("all broker tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
