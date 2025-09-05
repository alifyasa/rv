"""Show recent snapshots (like git log)."""

import sys
from pathlib import Path
from typing import Optional

from rv.config import CONFIG_DIR
from rv.utils import find_restic_dir, run_resticprofile, with_password


@with_password
def cmd_log(args: list[str]) -> None:
    """Show recent snapshots (like git status)"""
    restic_dir: Optional[Path] = find_restic_dir()
    if restic_dir is None:
        print(
            f"Error: not in a restic repository (no {CONFIG_DIR} found)",
            file=sys.stderr,
        )
        sys.exit(1)

    run_resticprofile("snapshots", "--compact", "--latest", "10", *args)
