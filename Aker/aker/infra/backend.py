"""Backend abstraction: pick an agent-CLI backend for one session.

The system drives agent work through a CLI subprocess (one of several
backends). Every backend implements `AgentSession` with the same
`send(prompt, timeout_sec=None) -> AgentResult` contract and maintains
its own session-id for multi-turn resume.

Selection policy for each `make_session()` call:

  1. `AKER_BACKEND` env var (``codex`` / ``claude``) — explicit, used
     for reproducibility in tests or forced runs.
  2. `backend=` kwarg passed to `make_session()` (overrides random).
  3. Otherwise: **random 50/50** between the registered backends.

Under parallel mode this means different slots may end up on different
backends, and even the worker vs. reviewer session within a single
round may land on different backends. That is intentional: maximum
coverage across models + harnesses without any manual orchestration.

Sandbox modes are backend-agnostic labels; each backend maps them to
its native concept (codex `--sandbox <mode>` / claude
`--allowedTools` + `--dangerously-skip-permissions`).
"""

from __future__ import annotations

import os
import random
from dataclasses import dataclass, field
from pathlib import Path
from typing import Protocol, Sequence

SANDBOX_READ_ONLY = "read-only"
SANDBOX_WORKSPACE_WRITE = "workspace-write"
SANDBOX_DANGER_FULL_ACCESS = "danger-full-access"

BACKEND_CODEX = "codex"
BACKEND_CLAUDE = "claude"

ALL_BACKENDS: tuple[str, ...] = (BACKEND_CODEX, BACKEND_CLAUDE)


class AgentError(RuntimeError):
    """Raised when the agent binary cannot be located or misconfigured."""


@dataclass
class AgentResult:
    """Backend-agnostic outcome of one `AgentSession.send()` call.

    Callers must only read these canonical fields. Backends may attach
    extra attributes on the dict-valued `raw` for debugging but must
    not require callers to look at them.
    """

    ok: bool
    exit_code: int
    stdout: str
    stderr: str
    final_message: str
    duration_sec: float
    files_created: list[Path] = field(default_factory=list)
    files_modified: list[Path] = field(default_factory=list)
    cmd: list[str] = field(default_factory=list)
    backend: str = ""
    session_id: str | None = None
    raw: dict = field(default_factory=dict)


class AgentSession(Protocol):
    """Protocol every backend's session class must satisfy."""

    cwd: Path
    session_id: str | None
    turn_count: int
    backend: str  # one of ALL_BACKENDS

    def send(
        self,
        prompt: str,
        timeout_sec: float | None = None,
    ) -> AgentResult: ...


def pick_backend(*, rng: random.Random | None = None) -> str:
    """Return ``codex`` or ``claude``.

    Honors `AKER_BACKEND` (case-insensitive) if set to a known value.
    Raises `AgentError` on an unknown forced value so typos surface
    loudly rather than silently falling back to random.
    """
    forced = os.environ.get("AKER_BACKEND", "").strip().lower()
    if forced:
        if forced not in ALL_BACKENDS:
            raise AgentError(
                f"AKER_BACKEND={forced!r} not in {ALL_BACKENDS}"
            )
        return forced
    r = rng if rng is not None else random
    return r.choice(ALL_BACKENDS)


def make_session(
    cwd: Path | str,
    *,
    sandbox: str = SANDBOX_WORKSPACE_WRITE,
    model: str | None = None,
    timeout_sec: float = 3600.0,
    extra_args: Sequence[str] | None = None,
    extra_env: dict[str, str] | None = None,
    backend: str | None = None,
    rng: random.Random | None = None,
) -> AgentSession:
    """Build a fresh `AgentSession`, choosing a backend.

    When `backend` is None, selection follows the policy documented
    at the top of this module. `model` / `extra_args` / `extra_env`
    are forwarded verbatim; if the randomly-picked backend cannot
    interpret them (e.g. a codex model name handed to claude), the
    failure surfaces on the first `send()` call, not here.
    """
    chosen = backend or pick_backend(rng=rng)
    if chosen == BACKEND_CODEX:
        from aker.infra.codex import CodexSession  # noqa: PLC0415
        return CodexSession(
            cwd=cwd,
            sandbox=sandbox,
            model=model,
            timeout_sec=timeout_sec,
            extra_args=extra_args,
            extra_env=extra_env,
        )
    if chosen == BACKEND_CLAUDE:
        from aker.infra.claude import ClaudeSession  # noqa: PLC0415
        return ClaudeSession(
            cwd=cwd,
            sandbox=sandbox,
            model=model,
            timeout_sec=timeout_sec,
            extra_args=extra_args,
            extra_env=extra_env,
        )
    raise AgentError(f"unknown backend {chosen!r}")
