"""Claude Code CLI backend for aker.

Drives `claude -p --output-format json` non-interactively, with the
same `AgentSession.send()` contract as the codex backend (see
`aker/infra/backend.py`).

Key protocol differences from codex (worth keeping in mind):

- Session id is **pre-assigned by us** via `--session-id <uuid>` on
  turn 1. Turn 2+ uses `--resume <uuid>`. No banner parsing needed
  (codex's dance).
- Claude emits a **single JSON object** for `-p --output-format json`
  (not an array); the final assistant text lives at the top-level
  `result` field, and Claude echoes its own `session_id` back. We
  cross-check.
- Claude has no OS-level read-only sandbox. We approximate
  `SANDBOX_READ_ONLY` by restricting `--tools` to read-only ones
  (Read / Glob / Grep) so Write/Edit/NotebookEdit/Bash are literally
  unavailable to the agent.
- Requires `IS_SANDBOX=1` in the subprocess env when combined with
  `--dangerously-skip-permissions` / `--permission-mode bypassPermissions`
  (user convention; also suppresses the "trust this directory" gate).
"""

from __future__ import annotations

import json
import logging
import os
import shutil
import subprocess
import time
import uuid
from pathlib import Path
from typing import Sequence

from aker.infra.backend import (
    BACKEND_CLAUDE,
    SANDBOX_DANGER_FULL_ACCESS,
    SANDBOX_READ_ONLY,
    SANDBOX_WORKSPACE_WRITE,
    AgentError,
    AgentResult,
)

log = logging.getLogger(__name__)

# Tools that never touch the filesystem in a write-ful way — used for
# SANDBOX_READ_ONLY. Claude's native tool set, not bash patterns.
READ_ONLY_TOOLS: tuple[str, ...] = ("Read", "Glob", "Grep")


def _snapshot_tree(root: Path) -> dict[Path, tuple[float, int]]:
    if not root.exists():
        return {}
    snap: dict[Path, tuple[float, int]] = {}
    for p in root.rglob("*"):
        if p.is_file():
            try:
                st = p.stat()
            except FileNotFoundError:
                continue
            snap[p.relative_to(root)] = (st.st_mtime, st.st_size)
    return snap


def _diff_snapshots(
    before: dict[Path, tuple[float, int]],
    after: dict[Path, tuple[float, int]],
) -> tuple[list[Path], list[Path]]:
    created: list[Path] = []
    modified: list[Path] = []
    for path, meta in after.items():
        prev = before.get(path)
        if prev is None:
            created.append(path)
        elif prev != meta:
            modified.append(path)
    return sorted(created), sorted(modified)


class ClaudeSession:
    """Multi-turn Claude Code session with pre-assigned session-id.

    One instance = one logical session. Turn 1 starts a fresh claude
    subprocess with `--session-id <uuid>`; subsequent turns use
    `--resume <uuid>`. State is persisted on disk by Claude Code
    itself under `~/.claude/projects/<hash>/sessions/<uuid>.jsonl`.
    We do not clean that up — it's small and Claude rotates.
    """

    backend: str = BACKEND_CLAUDE

    def __init__(
        self,
        cwd: Path | str,
        binary: str = "claude",
        model: str | None = None,
        sandbox: str = SANDBOX_WORKSPACE_WRITE,
        skip_git_check: bool = True,  # accepted for signature parity; unused
        timeout_sec: float = 3600.0,
        extra_args: Sequence[str] | None = None,
        extra_env: dict[str, str] | None = None,
    ) -> None:
        resolved = shutil.which(binary)
        if resolved is None:
            raise AgentError(f"claude binary not found on PATH: {binary}")
        self.binary = resolved
        self.cwd = Path(cwd).resolve()
        self.cwd.mkdir(parents=True, exist_ok=True)
        self.model = model
        self.sandbox = sandbox
        self.timeout_sec = timeout_sec
        self.extra_args = list(extra_args or [])
        self.extra_env: dict[str, str] = dict(extra_env or {})
        self.session_id: str | None = None
        self.turn_count: int = 0

    # ---------------- internal argv construction ----------------

    def _sandbox_argv(self) -> list[str]:
        """Map our sandbox label onto claude flags."""
        bypass_args = [
            "--dangerously-skip-permissions",
            "--permission-mode", "bypassPermissions",
        ]
        if self.sandbox == SANDBOX_READ_ONLY:
            # Restrict the built-in tool set to purely read-only.
            # Without Write/Edit/Bash in `--tools`, the agent literally
            # cannot call them (claude will reply "that tool is not
            # available"), which is the best logic-level approximation
            # to codex's OS-level read-only mount.
            return [
                "--tools", *READ_ONLY_TOOLS,
                *bypass_args,
            ]
        # Workspace-write and full-access both map to "all tools, no
        # permission prompts" — claude has no cheap way to partition
        # writes within vs. outside cwd, and we set cwd on the subprocess
        # to confine filesystem work to the task dir.
        return bypass_args

    def _build_argv(self, prompt: str) -> list[str]:
        argv: list[str] = [self.binary]
        # Put permission/tool flags before `-p <prompt>`. Newer Claude
        # versions accept flags after the prompt syntactically, but the
        # permission mode can still land as "default" in SDK transcripts.
        argv += self._sandbox_argv()
        if self.session_id is None:
            # First turn — pre-assign the uuid so we never have to parse
            # it back out of claude's output.
            self.session_id = str(uuid.uuid4())
            argv += ["--session-id", self.session_id]
        else:
            argv += ["--resume", self.session_id]
        argv += ["-p", prompt, "--output-format", "json"]
        if self.model:
            argv += ["--model", self.model]
        argv += self.extra_args
        return argv

    # ---------------- public: one turn -----------------

    def send(
        self,
        prompt: str,
        timeout_sec: float | None = None,
    ) -> AgentResult:
        snap_before = _snapshot_tree(self.cwd)
        argv = self._build_argv(prompt)
        timeout = timeout_sec if timeout_sec is not None else self.timeout_sec

        sub_env = os.environ.copy()
        sub_env["IS_SANDBOX"] = "1"
        sub_env.update(self.extra_env)

        log.info(
            "ClaudeSession.send cwd=%s sandbox=%s turn=%d session=%s",
            self.cwd, self.sandbox, self.turn_count + 1,
            self.session_id or "<new>",
        )
        log.debug("ClaudeSession.send cmd=%s", argv)

        t0 = time.monotonic()
        try:
            completed = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=str(self.cwd),
                env=sub_env,
            )
        except subprocess.TimeoutExpired as e:
            duration = time.monotonic() - t0
            log.warning("ClaudeSession.send timeout after %.1fs", duration)
            return AgentResult(
                ok=False,
                exit_code=-1,
                stdout=e.stdout or "" if isinstance(e.stdout, str) else "",
                stderr=(e.stderr or "" if isinstance(e.stderr, str) else "")
                + f"\n[aker] claude timed out after {duration:.1f}s",
                final_message="",
                duration_sec=duration,
                cmd=argv,
                backend=BACKEND_CLAUDE,
                session_id=self.session_id,
            )
        duration = time.monotonic() - t0

        final_message, raw_json = _extract_result_from_json(completed.stdout)
        snap_after = _snapshot_tree(self.cwd)
        created, modified = _diff_snapshots(snap_before, snap_after)

        self.turn_count += 1

        # claude's own self-reported error flag overrides exit code
        # optimism (exit 0 can still come with is_error=True; unlikely,
        # but we defend).
        is_error = bool(raw_json.get("is_error"))
        ok = completed.returncode == 0 and not is_error

        # Sanity: if claude echoed a different session_id than what we
        # pre-assigned, log it — something diverged.
        echoed_id = raw_json.get("session_id")
        if echoed_id and self.session_id and echoed_id != self.session_id:
            log.warning(
                "ClaudeSession: echoed session_id %s != pre-assigned %s",
                echoed_id, self.session_id,
            )

        if not ok:
            log.warning(
                "ClaudeSession.send rc=%d is_error=%s stop_reason=%s",
                completed.returncode, is_error, raw_json.get("stop_reason"),
            )

        return AgentResult(
            ok=ok,
            exit_code=completed.returncode,
            stdout=completed.stdout,
            stderr=completed.stderr,
            final_message=final_message,
            duration_sec=duration,
            files_created=created,
            files_modified=modified,
            cmd=argv,
            backend=BACKEND_CLAUDE,
            session_id=self.session_id,
            raw=raw_json,
        )


def _extract_result_from_json(stdout: str) -> tuple[str, dict]:
    """Parse claude's `-p --output-format json` stdout.

    Returns `(final_message, raw_dict)`. `raw_dict` is empty on parse
    failure. `final_message` is `raw['result']` (the top-level final
    assistant text); empty string if not present.

    Accepts both the single-object shape (expected) and the array
    shape (defensive against a possible future CLI change). In the
    array case, the last object with `type=='result'` wins.
    """
    if not stdout:
        return "", {}
    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        # Some `stream-json`-ish outputs may have leading non-JSON
        # preamble; try last non-empty line too.
        for line in reversed(stdout.splitlines()):
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                break
            except json.JSONDecodeError:
                continue
        else:
            log.warning("ClaudeSession: stdout was not valid JSON")
            return "", {}
    if isinstance(data, dict):
        result = data.get("result", "") or ""
        return str(result), data
    if isinstance(data, list):
        for msg in reversed(data):
            if isinstance(msg, dict) and msg.get("type") == "result":
                return str(msg.get("result", "") or ""), msg
        return "", {}
    return "", {}
