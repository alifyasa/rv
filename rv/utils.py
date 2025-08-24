"""Utility functions for repository discovery and resticprofile execution."""

import sys
import subprocess
from pathlib import Path
from typing import Optional

from rv.config import CONFIG_DIR


def find_restic_dir() -> Optional[Path]:
    """Find .rv directory by walking up from current directory"""
    current: Path = Path.cwd()
    for parent in [current, *current.parents]:
        restic_dir: Path = parent / CONFIG_DIR
        if restic_dir.is_dir():
            return restic_dir
    return None


def get_config_path(restic_dir: Path) -> str:
    """Get the path to the resticprofile config file"""
    config_file: Path = restic_dir / "config.yaml"
    if not config_file.exists():
        print(f"Error: {config_file} not found", file=sys.stderr)
        sys.exit(1)
    return str(config_file)


def run_resticprofile(*args: str) -> None:
    """Run resticprofile with the given arguments"""
    restic_dir: Optional[Path] = find_restic_dir()
    if restic_dir is None:
        print(
            f"Error: not in a restic repository (no {CONFIG_DIR} found)",
            file=sys.stderr,
        )
        sys.exit(1)

    config_path: str = get_config_path(restic_dir)
    cmd: list[str] = ["resticprofile", "-c", config_path] + list(args)
    result = subprocess.run(cmd)
    sys.exit(result.returncode)
