"""Human guidance with a per-round TTL.

A task can carry an optional `guidance.md` file at its root. The
file's frontmatter records when it was created (in terms of total
reservation-open count) and how many rounds it lives for. At each
round start the iterate phase reads the file; if the TTL is
exceeded, the file is moved to `_guidance_archive/<ts>.md` and the
worker prompt is rendered without a guidance block.

Design intent (see conversation log around 2026-04-24): permanent
human guidance biases the search forever (anti-anchoring fail). A
TTL'd hint expires automatically; the user can re-write between
runs, but the system enforces self-cleaning.

File format:

```
---
created_at: 2026-04-24T15:30:00+00:00
created_at_open_count: 7
ttl_rounds: 10
---

# Constraints
...

# Suggestions
...
```

Body is free-form markdown. The frontmatter keys are required for
TTL bookkeeping. By convention the body uses `## Constraints` for
binding-ish facts and `## Suggestions` for advisory hints, but the
prompt does not enforce this.
"""

from __future__ import annotations

import json
import logging
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

log = logging.getLogger(__name__)

GUIDANCE_FILE = "guidance.md"
ARCHIVE_DIR = "_guidance_archive"
RESERVATIONS_FILE = "_reservations.jsonl"


@dataclass
class Guidance:
    """Active guidance plus its TTL bookkeeping."""

    body: str
    created_at: str
    created_at_open_count: int
    ttl_rounds: int

    def remaining(self, current_open_count: int) -> int:
        return max(0, self.created_at_open_count + self.ttl_rounds - current_open_count)

    def is_expired(self, current_open_count: int) -> bool:
        return current_open_count > self.created_at_open_count + self.ttl_rounds


def count_reservation_opens(task_dir: Path | str) -> int:
    """Total number of `event: open` records in `_reservations.jsonl`."""
    path = Path(task_dir) / RESERVATIONS_FILE
    if not path.is_file():
        return 0
    n = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            evt = json.loads(line)
        except json.JSONDecodeError:
            continue
        if evt.get("event") == "open":
            n += 1
    return n


def _parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Parse a tiny `---\\nkey: value\\n---\\nbody` frontmatter.

    Not YAML — just `key: value` lines. Returns ({}, text) if no
    frontmatter is detected, so legacy guidance.md without a header
    just shows up as a body with no metadata (will fail TTL check
    later and get archived defensively).
    """
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text
    fm_text = text[4:end]
    body = text[end + 5 :].lstrip("\n")
    metadata: dict[str, str] = {}
    for line in fm_text.splitlines():
        if ":" not in line:
            continue
        k, _, v = line.partition(":")
        metadata[k.strip()] = v.strip()
    return metadata, body


def _format_frontmatter(meta: dict[str, str | int]) -> str:
    lines = ["---"]
    for k, v in meta.items():
        lines.append(f"{k}: {v}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def read(task_dir: Path | str) -> Guidance | None:
    """Read guidance.md if present and parseable; else None.

    Does NOT check expiration — callers wanting expiration should use
    `read_active(task_dir)`.
    """
    path = Path(task_dir) / GUIDANCE_FILE
    if not path.is_file():
        return None
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return None
    meta, body = _parse_frontmatter(text)
    try:
        return Guidance(
            body=body,
            created_at=str(meta.get("created_at", "")),
            created_at_open_count=int(meta.get("created_at_open_count", "0")),
            ttl_rounds=int(meta.get("ttl_rounds", "0")),
        )
    except (TypeError, ValueError):
        # Malformed frontmatter — treat as no guidance and let the
        # caller archive defensively.
        return None


def archive(task_dir: Path | str, *, reason: str = "expired") -> Path | None:
    """Move guidance.md to `_guidance_archive/<ts>-<reason>.md`.

    Returns the destination path, or None if there was no file to move
    (already gone — common under concurrent slots).
    """
    task_dir = Path(task_dir).resolve()
    src = task_dir / GUIDANCE_FILE
    if not src.is_file():
        return None
    archive_dir = task_dir / ARCHIVE_DIR
    archive_dir.mkdir(exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    dest = archive_dir / f"{ts}-{reason}.md"
    # If two slots race, only the first rename succeeds; subsequent
    # callers see FileNotFoundError and silently no-op.
    try:
        shutil.move(str(src), str(dest))
        log.info("guidance: archived %s → %s", src.name, dest.name)
        return dest
    except FileNotFoundError:
        return None


def read_active(task_dir: Path | str) -> Guidance | None:
    """Return the active guidance for this task, or None.

    `Active` means: file exists, parseable frontmatter, and current
    reservation open count has not exceeded the TTL. Expired files are
    archived as a side effect.
    """
    task_dir = Path(task_dir).resolve()
    g = read(task_dir)
    if g is None:
        # File missing or malformed. If a malformed file exists, archive
        # so it doesn't keep tripping read attempts.
        if (task_dir / GUIDANCE_FILE).is_file():
            archive(task_dir, reason="malformed")
        return None
    current = count_reservation_opens(task_dir)
    if g.is_expired(current):
        archive(task_dir, reason="expired")
        return None
    return g


def write(
    task_dir: Path | str,
    body: str,
    *,
    ttl_rounds: int,
) -> Guidance:
    """Write a fresh guidance.md, archiving any prior guidance first.

    `ttl_rounds` is the number of upcoming reservation opens during
    which the guidance stays active.
    """
    if ttl_rounds < 1:
        raise ValueError(f"ttl_rounds must be >= 1, got {ttl_rounds}")
    task_dir = Path(task_dir).resolve()
    task_dir.mkdir(parents=True, exist_ok=True)
    archive(task_dir, reason="superseded")
    open_count = count_reservation_opens(task_dir)
    created_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    meta: dict[str, str | int] = {
        "created_at": created_at,
        "created_at_open_count": open_count,
        "ttl_rounds": ttl_rounds,
    }
    path = task_dir / GUIDANCE_FILE
    path.write_text(_format_frontmatter(meta) + "\n" + body.rstrip() + "\n", encoding="utf-8")
    return Guidance(
        body=body.rstrip(),
        created_at=created_at,
        created_at_open_count=open_count,
        ttl_rounds=ttl_rounds,
    )


def render_for_prompt(task_dir: Path | str) -> str:
    """Return the worker-prompt-ready guidance block, or '' if none.

    Block has its own header line that exposes the staleness signal:

        ## Human guidance (active for N more round(s) of M)

        <body>

    Empty string means no guidance — the iterate prompt's
    `<<HUMAN_GUIDANCE>>` placeholder collapses cleanly.
    """
    task_dir = Path(task_dir).resolve()
    g = read_active(task_dir)
    if g is None:
        return ""
    current = count_reservation_opens(task_dir)
    remaining = g.remaining(current)
    return (
        f"## Human guidance (active for {remaining} more round(s) of {g.ttl_rounds})\n"
        f"\n{g.body.strip()}\n"
    )


def archived_files(task_dir: Path | str) -> Iterable[Path]:
    archive_dir = Path(task_dir) / ARCHIVE_DIR
    if not archive_dir.is_dir():
        return []
    return sorted(archive_dir.iterdir())
