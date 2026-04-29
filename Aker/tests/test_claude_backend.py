"""Standalone smoke for the Claude Code backend.

Exercises:

- `pick_backend()` respects `AKER_BACKEND` env override.
- `make_session()` dispatches to `ClaudeSession` when forced.
- `ClaudeSession` round-trip: send a trivial prompt, session_id is
  pre-assigned (UUID we generate), result.final_message parses out.
- Resume across turns: turn 2 remembers turn 1's content.
- File-creating prompt: SANDBOX_WORKSPACE_WRITE (via
  `--dangerously-skip-permissions` plus `--permission-mode bypassPermissions`)
  lets the agent write a file
  under cwd; we verify it landed.

Requires the `claude` CLI on PATH and a working Claude Code auth
(OAuth token or ANTHROPIC_API_KEY). Skips gracefully if absent.

Run:

    python tests/test_claude_backend.py
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from aker.infra.backend import (  # noqa: E402
    BACKEND_CLAUDE,
    BACKEND_CODEX,
    SANDBOX_READ_ONLY,
    SANDBOX_WORKSPACE_WRITE,
    AgentError,
    make_session,
    pick_backend,
)
from aker.infra.claude import ClaudeSession  # noqa: E402


def _skip_if_no_claude() -> None:
    if shutil.which("claude") is None:
        print("SKIP: `claude` CLI not on PATH")
        sys.exit(0)


def test_pick_backend_env_override() -> None:
    # forced valid
    for name in (BACKEND_CODEX, BACKEND_CLAUDE):
        os.environ["AKER_BACKEND"] = name
        assert pick_backend() == name, name
    # forced invalid → raises
    os.environ["AKER_BACKEND"] = "not_a_backend"
    try:
        pick_backend()
    except AgentError:
        print("[env override] OK")
    else:
        raise AssertionError("expected AgentError")
    os.environ.pop("AKER_BACKEND", None)


def test_factory_dispatch() -> None:
    os.environ["AKER_BACKEND"] = "claude"
    with tempfile.TemporaryDirectory() as td:
        s = make_session(td, timeout_sec=30)
        assert isinstance(s, ClaudeSession), type(s)
    os.environ.pop("AKER_BACKEND", None)
    print("[factory  ] OK dispatches to ClaudeSession on env override")


def test_claude_roundtrip_and_resume() -> None:
    _skip_if_no_claude()
    with tempfile.TemporaryDirectory() as td:
        sess = ClaudeSession(
            cwd=Path(td),
            model="sonnet",
            sandbox=SANDBOX_WORKSPACE_WRITE,
            timeout_sec=120,
        )
        r1 = sess.send("Reply with exactly the string: aker-claude-echo-42")
        assert r1.ok, f"turn 1 not ok: exit={r1.exit_code} stderr={r1.stderr[:300]}"
        assert "aker-claude-echo-42" in r1.final_message, r1.final_message
        assert sess.session_id is not None
        assert r1.backend == BACKEND_CLAUDE
        assert r1.session_id == sess.session_id
        print(f"[turn 1   ] OK dur={r1.duration_sec:.1f}s final_message={r1.final_message!r}")

        r2 = sess.send("Echo back that same string from turn 1, verbatim.")
        assert r2.ok, f"turn 2 not ok: exit={r2.exit_code}"
        assert r2.session_id == r1.session_id, "session_id should persist across turns"
        assert "aker-claude-echo-42" in r2.final_message, (
            f"resume memory broken: {r2.final_message!r}"
        )
        print(f"[turn 2   ] OK dur={r2.duration_sec:.1f}s resume worked")


def test_claude_write_permission() -> None:
    _skip_if_no_claude()
    with tempfile.TemporaryDirectory() as td:
        cwd = Path(td)
        sess = ClaudeSession(
            cwd=cwd,
            model="sonnet",
            sandbox=SANDBOX_WORKSPACE_WRITE,
            timeout_sec=120,
        )
        prompt = (
            "Create a file called hello.txt in the current working "
            "directory containing exactly the text: aker-wrote-this. "
            "Then reply with the string: done."
        )
        r = sess.send(prompt)
        assert r.ok, f"not ok: exit={r.exit_code} stderr={r.stderr[:300]}"
        target = cwd / "hello.txt"
        assert target.is_file(), (
            f"hello.txt not created; files_created={[str(p) for p in r.files_created]}"
        )
        content = target.read_text().strip()
        assert "aker-wrote-this" in content, f"unexpected content: {content!r}"
        assert Path("hello.txt") in r.files_created, (
            f"diff didn't catch the write; files_created={r.files_created}"
        )
        print(f"[write perm] OK created hello.txt='{content}' dur={r.duration_sec:.1f}s")


def test_claude_read_only_sandbox() -> None:
    _skip_if_no_claude()
    with tempfile.TemporaryDirectory() as td:
        cwd = Path(td)
        # pre-stage a file the agent can read
        (cwd / "note.txt").write_text("secret-42\n")
        sess = ClaudeSession(
            cwd=cwd,
            model="sonnet",
            sandbox=SANDBOX_READ_ONLY,
            timeout_sec=120,
        )
        prompt = (
            "Read the file note.txt in the current working directory and "
            "reply with exactly its first line (trimmed)."
        )
        r = sess.send(prompt)
        assert r.ok, f"not ok: exit={r.exit_code} stderr={r.stderr[:300]}"
        assert "secret-42" in r.final_message, r.final_message
        print(f"[read-only ] OK read note.txt via restricted toolset")


def main() -> int:
    test_pick_backend_env_override()
    test_factory_dispatch()
    test_claude_roundtrip_and_resume()
    test_claude_write_permission()
    test_claude_read_only_sandbox()
    print("all claude backend tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
