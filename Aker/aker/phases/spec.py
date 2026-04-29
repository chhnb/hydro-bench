"""Spec phase — turn a natural-language description into `spec.md`.

Public entry point: `run(task_dir, description, ...) -> SpecReport`. The
feature loads `aker/prompts/spec_generator.md`, substitutes the user's
description into `<<USER_INPUT>>`, runs it through one-shot agent (codex
or claude — randomly chosen per invocation unless `AKER_BACKEND` forces
one), and checks that `spec.md` landed in the task directory.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path

from aker.infra.backend import AgentResult, make_session

log = logging.getLogger(__name__)

PROMPT_PATH = Path(__file__).parent.parent / "prompts" / "spec_generator.md"

USER_INPUT_PLACEHOLDER = "<<USER_INPUT>>"


@dataclass
class SpecReport:
    """Outcome of one `spec.run` invocation.

    `status` is one of:
      - "OK"               — agent exited 0 and `spec.md` exists
      - "FAIL_AGENT"       — agent (codex/claude) exited non-zero
      - "FAIL_NO_SPEC_MD"  — agent succeeded but did not produce spec.md
    """

    status: str
    spec_path: Path
    result: AgentResult

    @property
    def ok(self) -> bool:
        return self.status == "OK"

    # Backwards-compat alias. Older callers (tests, CLI) access `.codex`;
    # forward it to the generic `.result` regardless of which backend
    # actually ran.
    @property
    def codex(self) -> AgentResult:
        return self.result


def run(
    task_dir: Path | str,
    description: str,
    *,
    model: str | None = None,
    timeout_sec: float = 1800.0,
) -> SpecReport:
    """Write `spec.md` into `task_dir` by prompting an agent with `description`.

    Creates `task_dir` if it does not exist. Idempotent only in the sense
    that a second call will overwrite the prior `spec.md`; callers that
    want skip-if-present behaviour should check for the file first.
    """
    task_dir = Path(task_dir).resolve()
    task_dir.mkdir(parents=True, exist_ok=True)

    template = PROMPT_PATH.read_text()
    if USER_INPUT_PLACEHOLDER not in template:
        raise RuntimeError(
            f"spec_generator.md must contain {USER_INPUT_PLACEHOLDER}"
        )
    prompt = template.replace(USER_INPUT_PLACEHOLDER, description)

    session = make_session(task_dir, timeout_sec=timeout_sec, model=model)
    log.info(
        "spec.run cwd=%s backend=%s prompt_chars=%d",
        task_dir, session.backend, len(prompt),
    )
    result = session.send(prompt)

    spec_path = task_dir / "spec.md"
    if not result.ok:
        status = "FAIL_AGENT"
    elif not spec_path.exists():
        status = "FAIL_NO_SPEC_MD"
    else:
        status = "OK"
    return SpecReport(status=status, spec_path=spec_path, result=result)
