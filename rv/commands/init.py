"""Initialize a new restic repository configuration."""

import os
import sys
import subprocess
import shutil
import argparse
from pathlib import Path
from typing import Optional

from rv.config import CONFIG_DIR, CONFIG_TEMPLATE
from rv.utils import get_config_path, with_password_confirmation


@with_password_confirmation
def cmd_init(args: list[str]) -> None:
    """Initialize a new restic repository configuration"""
    # Parse arguments for repository option
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        prog="rv init", description="Initialize a new restic repository configuration"
    )
    parser.add_argument(
        "--repository",
        "-r",
        help="Repository location (e.g., local:path, s3:bucket, etc.)",
    )
    parser.add_argument(
        "--setup-only",
        action="store_true",
        help="Only create .rv directory structure, skip resticprofile init",
    )
    parser.add_argument(
        "--override",
        action="store_true",
        help="Override existing .rv directory by creating temporary directory and atomically replacing",
    )

    try:
        parsed_args, _ = parser.parse_known_args(args)
    except SystemExit:
        return

    repository: Optional[str] = parsed_args.repository
    setup_only: bool = parsed_args.setup_only
    override: bool = parsed_args.override

    # If no repository specified and not setup-only, ask for confirmation to use local
    if repository is None and not setup_only:
        response: str = (
            input("No repository specified. Create a local repository? (y/N): ")
            .strip()
            .lower()
        )
        if response not in ["y", "yes"]:
            print("Repository initialization cancelled.")
            sys.exit(1)
        repository = "local:.rv/repo"
    elif repository is None and setup_only:
        repository = "local:.rv/repo"

    restic_dir: Path = Path(CONFIG_DIR)

    if restic_dir.exists() and not override:
        print(f"Error: {CONFIG_DIR} directory already exists")
        sys.exit(1)

    # Use temporary directory when overriding existing installation
    temp_dir: Optional[Path] = None
    if override:
        temp_dir = Path(f"{CONFIG_DIR}.tmp")
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        restic_dir = temp_dir

    try:
        # Create directory structure
        restic_dir.mkdir(parents=True)

        # Create config.yaml file using template
        config_content: str = CONFIG_TEMPLATE.format(repository=repository)
        (restic_dir / "config.yaml").write_text(config_content)

        excludes_content: str = f"./{CONFIG_DIR}/repo/\n**/.git/"

        excludes_file: Path = restic_dir / ".rvignore"
        excludes_file.write_text(excludes_content)
        excludes_file.chmod(0o644)

        parent_exclude: Path = restic_dir.parent / ".rvignore"
        parent_exclude.touch(exist_ok=True)

        if not setup_only:
            config_path: str = get_config_path(restic_dir)
            cmd: list[str] = ["resticprofile", "-c", config_path, "init"] + list(args)
            subprocess.run(cmd, check=True, env=os.environ)

        # Perform atomic swap if using override
        if override and temp_dir is not None:
            original_dir: Path = Path(CONFIG_DIR)
            if original_dir.exists():
                shutil.rmtree(original_dir)
            temp_dir.rename(original_dir)

        print(f"Initialized restic configuration in {CONFIG_DIR}/")
    except (OSError, subprocess.SubprocessError) as e:
        # Clean up on any error
        if restic_dir.exists():
            shutil.rmtree(restic_dir)
        # Also clean up temp directory if it was created
        if override and temp_dir is not None and temp_dir.exists():
            shutil.rmtree(temp_dir)
        print(f"Error during initialization: {e}", file=sys.stderr)
        sys.exit(1)
