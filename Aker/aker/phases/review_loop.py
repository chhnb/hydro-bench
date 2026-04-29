"""General worker + reviewer review loop, reusable across phases.

Each phase (bootstrap, iterate, …) supplies its own `ReviewPrompts`
(worker initial, reviewer initial, worker-fix template, reviewer-recheck
template) plus sandbox / timeout knobs. The loop itself does not know
what the worker is producing — it only drives the dialog and parses
the reviewer's verdict.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from aker.infra.backend import (
    SANDBOX_DANGER_FULL_ACCESS,
    SANDBOX_READ_ONLY,
    AgentResult,
    AgentSession,
    make_session,
)

log = logging.getLogger(__name__)

_VERDICT_RE = re.compile(r"VERDICT:\s*(PASS|RETRY)\b", re.IGNORECASE)

VERDICT_REVIEWER_PLACEHOLDER = "<<REVIEWER_VERDICT>>"
WORKER_FINAL_PLACEHOLDER = "<<WORKER_FINAL_MESSAGE>>"


def parse_verdict(msg: str) -> str | None:
    """Return "PASS", "RETRY", or None from a reviewer message."""
    if not msg:
        return None
    for line in reversed(msg.splitlines()):
        match = _VERDICT_RE.search(line)
        if match:
            return match.group(1).upper()
    return None


@dataclass(frozen=True)
class ReviewPrompts:
    """Four prompts that parameterize one review loop.

    - `worker_initial`: worker turn 1. Must describe the output contract
      and ask the worker to self-validate before replying.
    - `reviewer_initial`: reviewer turn 1. Must describe what to flag,
      what not to flag, and enforce the VERDICT line format.
    - `worker_fix_template`: worker follow-up turns. Must contain the
      literal substring `<<REVIEWER_VERDICT>>`.
    - `reviewer_recheck_template`: reviewer follow-up turns. Must
      contain the literal substring `<<WORKER_FINAL_MESSAGE>>`.
    """

    worker_initial: str
    reviewer_initial: str
    worker_fix_template: str
    reviewer_recheck_template: str

    def validate(self) -> None:
        if VERDICT_REVIEWER_PLACEHOLDER not in self.worker_fix_template:
            raise ValueError(
                f"worker_fix_template must contain {VERDICT_REVIEWER_PLACEHOLDER}"
            )
        if WORKER_FINAL_PLACEHOLDER not in self.reviewer_recheck_template:
            raise ValueError(
                f"reviewer_recheck_template must contain {WORKER_FINAL_PLACEHOLDER}"
            )


@dataclass
class ReviewTurn:
    actor: str  # "worker" | "reviewer"
    attempt: int  # 1-based
    result: AgentResult


@dataclass
class ReviewLoopResult:
    """Outcome of a single `run_review_loop` invocation.

    `status` is one of:
      - "OK"                       — reviewer issued VERDICT: PASS
      - "FAIL_WORKER_CRASH"        — worker subprocess returned non-zero
      - "FAIL_REVIEWER_EXHAUSTED"  — max_retries consecutive RETRYs
      - "FAIL_VERDICT_UNPARSED"    — reviewer reply had no VERDICT line
    """

    status: str
    attempts: int
    transcript: list[ReviewTurn] = field(default_factory=list)
    worker_session_id: str | None = None
    reviewer_session_id: str | None = None


def run_review_loop(
    task_dir: Path | str,
    prompts: ReviewPrompts,
    *,
    max_retries: int = 3,
    worker_sandbox: str = SANDBOX_DANGER_FULL_ACCESS,
    reviewer_sandbox: str = SANDBOX_READ_ONLY,
    worker_timeout_sec: float = 3600.0,
    reviewer_timeout_sec: float = 1800.0,
    log_path: Path | str | None = None,
    model: str | None = None,
    worker: AgentSession | None = None,
    reviewer: AgentSession | None = None,
    after_worker_turn: Callable[[int, AgentResult], None] | None = None,
) -> ReviewLoopResult:
    """Run one worker + reviewer dialog against `task_dir`.

    `task_dir` is passed to both agent sessions as their working root.
    The worker gets `worker_sandbox` (default: full access, so it can
    compile + run CUDA for self-validation); the reviewer gets
    `reviewer_sandbox` (default: read-only, so it can cat / ls / jq
    but cannot write).

    `worker` and `reviewer`, if passed, are reused across calls — the
    caller owns their lifecycle. This is how the iterate phase carries
    worker state across rounds (see `aker.iterate.run`). If either is
    `None`, a fresh session is created here; the backend (codex vs.
    claude) is chosen at random per `make_session()` unless
    `AKER_BACKEND` forces one. Worker and reviewer are chosen
    independently — they may end up on different backends.
    """
    task_dir = Path(task_dir).resolve()
    task_dir.mkdir(parents=True, exist_ok=True)
    prompts.validate()

    if worker is None:
        worker = make_session(
            cwd=task_dir,
            sandbox=worker_sandbox,
            timeout_sec=worker_timeout_sec,
            model=model,
        )
    if reviewer is None:
        reviewer = make_session(
            cwd=task_dir,
            sandbox=reviewer_sandbox,
            timeout_sec=reviewer_timeout_sec,
            model=model,
        )

    transcript: list[ReviewTurn] = []

    log.info("review_loop: worker turn 1")
    w_result = worker.send(prompts.worker_initial)
    transcript.append(ReviewTurn("worker", 1, w_result))
    if not w_result.ok:
        return _finalize(
            "FAIL_WORKER_CRASH", 1, transcript, worker, reviewer, log_path
        )
    if after_worker_turn is not None:
        try:
            after_worker_turn(1, w_result)
        except Exception:  # noqa: BLE001
            log.exception("review_loop: after_worker_turn hook failed on turn 1")

    status = "FAIL_REVIEWER_EXHAUSTED"
    attempt = 1
    for attempt in range(1, max_retries + 1):
        if attempt == 1:
            r_prompt = prompts.reviewer_initial
        else:
            r_prompt = prompts.reviewer_recheck_template.replace(
                WORKER_FINAL_PLACEHOLDER, w_result.final_message
            )
        log.info("review_loop: reviewer turn %d", attempt)
        r_result = reviewer.send(r_prompt)
        transcript.append(ReviewTurn("reviewer", attempt, r_result))

        verdict = parse_verdict(r_result.final_message)
        if verdict is None:
            log.warning(
                "review_loop: reviewer reply on attempt %d had no VERDICT line",
                attempt,
            )
            status = "FAIL_VERDICT_UNPARSED"
            break
        if verdict == "PASS":
            log.info("review_loop: PASS on attempt %d", attempt)
            status = "OK"
            break
        if attempt == max_retries:
            log.warning(
                "review_loop: reviewer still RETRY after %d attempt(s); giving up",
                attempt,
            )
            status = "FAIL_REVIEWER_EXHAUSTED"
            break

        log.info("review_loop: worker turn %d (fix)", attempt + 1)
        fix_prompt = prompts.worker_fix_template.replace(
            VERDICT_REVIEWER_PLACEHOLDER, r_result.final_message
        )
        w_result = worker.send(fix_prompt)
        transcript.append(ReviewTurn("worker", attempt + 1, w_result))
        if not w_result.ok:
            status = "FAIL_WORKER_CRASH"
            break
        if after_worker_turn is not None:
            try:
                after_worker_turn(attempt + 1, w_result)
            except Exception:  # noqa: BLE001
                log.exception(
                    "review_loop: after_worker_turn hook failed on turn %d",
                    attempt + 1,
                )

    return _finalize(
        status, attempt, transcript, worker, reviewer, log_path
    )


def _finalize(
    status: str,
    attempts: int,
    transcript: list[ReviewTurn],
    worker: AgentSession,
    reviewer: AgentSession,
    log_path: Path | str | None,
) -> ReviewLoopResult:
    if log_path is not None:
        _write_log(
            Path(log_path),
            transcript=transcript,
            status=status,
            worker_session=worker.session_id,
            reviewer_session=reviewer.session_id,
        )
    return ReviewLoopResult(
        status=status,
        attempts=attempts,
        transcript=transcript,
        worker_session_id=worker.session_id,
        reviewer_session_id=reviewer.session_id,
    )


def _write_log(
    log_path: Path,
    *,
    transcript: list[ReviewTurn],
    status: str,
    worker_session: str | None,
    reviewer_session: str | None,
) -> None:
    lines: list[str] = []
    lines.append("# Review loop log")
    lines.append("")
    lines.append(
        f"- completed_at: `{datetime.now(timezone.utc).isoformat(timespec='seconds')}`"
    )
    lines.append(f"- status: `{status}`")
    lines.append(f"- worker_session_id: `{worker_session or 'n/a'}`")
    lines.append(f"- reviewer_session_id: `{reviewer_session or 'n/a'}`")
    lines.append(f"- turns: {len(transcript)}")
    lines.append("")
    for turn in transcript:
        lines.append("---")
        lines.append("")
        lines.append(
            f"## {turn.actor} — attempt {turn.attempt} "
            f"(dur={turn.result.duration_sec:.1f}s, exit={turn.result.exit_code})"
        )
        lines.append("")
        if turn.result.files_created:
            head = ", ".join(f"`{p}`" for p in turn.result.files_created[:20])
            tail = " …" if len(turn.result.files_created) > 20 else ""
            lines.append(
                f"**files_created** ({len(turn.result.files_created)}): {head}{tail}"
            )
            lines.append("")
        if turn.result.files_modified:
            head = ", ".join(f"`{p}`" for p in turn.result.files_modified[:20])
            tail = " …" if len(turn.result.files_modified) > 20 else ""
            lines.append(
                f"**files_modified** ({len(turn.result.files_modified)}): {head}{tail}"
            )
            lines.append("")
        lines.append("```")
        lines.append((turn.result.final_message or "").rstrip())
        lines.append("```")
        lines.append("")
    log_path.write_text("\n".join(lines))
