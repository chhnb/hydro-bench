"""Enable `python -m aker <subcommand> ...`."""

from __future__ import annotations

import sys

from aker.cli import main

if __name__ == "__main__":
    sys.exit(main())
