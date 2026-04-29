"""Smoke test for CodexClient. Asks codex to write a hello file."""

from __future__ import annotations

import argparse
import logging
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from aker.infra.codex import CodexClient  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default=None, help="codex --model override")
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )

    client = CodexClient(model=args.model, timeout_sec=args.timeout)
    print(f"codex version: {client.version()}")

    with tempfile.TemporaryDirectory(prefix="aker_demo_") as tmp:
        tmp_path = Path(tmp)
        prompt = (
            "Write a file named hello.txt in the current directory whose "
            "only contents are the line: hello from codex. "
            "Do not create any other files. Reply with only the word DONE."
        )
        print(f"\ncwd: {tmp_path}")
        print(f"prompt: {prompt}\n")

        result = client.run(prompt, cwd=tmp_path)

        print(f"ok={result.ok} exit={result.exit_code} dur={result.duration_sec:.1f}s")
        print(f"files_created: {result.files_created}")
        print(f"files_modified: {result.files_modified}")
        print(f"final_message: {result.final_message.strip()!r}")

        if not result.ok:
            print("\n---- STDERR ----\n" + result.stderr)
            return 1

        hello = tmp_path / "hello.txt"
        if hello.exists():
            print(f"\nhello.txt contents: {hello.read_text()!r}")
            return 0
        print("\nhello.txt was NOT created — codex did not follow instructions")
        return 2


if __name__ == "__main__":
    sys.exit(main())
