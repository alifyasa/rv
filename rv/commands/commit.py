import os
import sys
import subprocess
import argparse
from pathlib import Path
from typing import Optional

from rv.config import CONFIG_DIR
from rv.utils import (
    run_resticprofile_with_config,
    find_restic_dir,
    get_config_path,
    with_password,
)


@with_password
def cmd_commit(args: list[str]) -> None:
    """Commit changes to the restic repository"""
    restic_dir: Optional[Path] = find_restic_dir()
    if restic_dir is None:
        print(
            f"Error: not in a restic repository (no {CONFIG_DIR} found)",
            file=sys.stderr,
        )
        sys.exit(1)

    # Parse arguments to extract message flag
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        prog="rv commit", description="Commit changes to the restic repository"
    )
    parser.add_argument("--message", "-m", help="Commit message")

    try:
        parsed_args, remaining_args = parser.parse_known_args(args)
    except SystemExit:
        return

    message: Optional[str] = parsed_args.message
    commit_message_file: Path = restic_dir / "COMMIT_MESSAGE"

    if message is not None:
        # Write message to COMMIT_MESSAGE file
        commit_message_file.write_text(message + "\n")
    else:
        # Open editor for commit message
        editor: str = os.environ.get("EDITOR", "vi")

        # Create temporary message if file doesn't exist
        if not commit_message_file.exists():
            commit_message_file.write_text("\n# Enter commit message above\n")

        # Open editor
        try:
            subprocess.run([editor, str(commit_message_file)], check=True)
        except subprocess.CalledProcessError:
            print("Error: Failed to open editor", file=sys.stderr)
            sys.exit(1)
        except FileNotFoundError:
            print(
                f"Error: Editor '{editor}' not found. Set EDITOR environment variable.",
                file=sys.stderr,
            )
            sys.exit(1)

    # Run restic backup without the message flag
    config_path: str = get_config_path(restic_dir)

    try:
        run_resticprofile_with_config(config_path, "backup", *remaining_args)
    finally:
        # Delete COMMIT_MESSAGE after backup
        if commit_message_file.exists():
            commit_message_file.unlink()
