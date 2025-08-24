#!/usr/bin/env python3
"""
rv - Versioning using Restic
"""

import sys
import subprocess
import shutil
import argparse
import getpass
from pathlib import Path
from typing import Dict, Callable, Optional

# region Configuration

CONFIG_DIR: str = ".rv"

# endregion

# region Templates

CONFIG_TEMPLATE: str = (
    """
# yaml-language-server: $schema=https://creativeprojects.github.io/resticprofile/jsonschema/config.json

version: "1"

default:
  repository: "{repository}"
  password-command: |-
    rv get-pass

  backup:
    verbose: 1
    skip-if-unchanged: true
    exclude-file:            # Relative to config.yaml
     - ".rvignore"
     - "../.rvignore"
    source:
      - "."                  # Relative to CWD

  find:
    human-readable: true

  init:
    password-command: |-
      rv get-pass --confirm

  restore:
    target: .                # Relative to CWD
""".strip()
    + "\n"
)

# endregion

# region Utilities


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


# endregion

# region Commands


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
            subprocess.run(cmd, check=True)

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


def cmd_get_pass(args: list[str]) -> None:
    """Get password using getpass and print it back"""
    confirm: bool = "--confirm" in args

    password: str = getpass.getpass("Password: ")

    if confirm:
        confirm_password: str = getpass.getpass("Confirm password: ")
        if password != confirm_password:
            print("Error: passwords do not match", file=sys.stderr)
            sys.exit(1)

    print(password)


# endregion

# region Command Dispatch

# Command registry - add new commands here
COMMANDS: Dict[str, Callable[[list[str]], None]] = {
    "init": cmd_init,
    "log": cmd_log,
    "get-pass": cmd_get_pass,
    # Add more commands here...
}


def main() -> None:
    """Main function with command dispatch"""
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        prog="rv",
        description="Versioning using Restic",
        add_help=False,  # We'll handle help manually to pass through to resticprofile
    )

    # Parse known args to separate command from remaining args
    parser.add_argument("command", nargs="?", help="Command to execute")
    parser.add_argument("args", nargs="*", help="Arguments for the command")

    # Parse all arguments, allowing unknown ones to pass through
    try:
        parsed_args, unknown_args = parser.parse_known_args()
        command: Optional[str] = parsed_args.command
        args: list[str] = parsed_args.args + unknown_args
    except SystemExit:
        # If argparse fails (e.g., --help), pass everything to resticprofile
        run_resticprofile(*sys.argv[1:])
        return

    # Check if it's a custom command
    if command in COMMANDS:
        COMMANDS[command](args)
        return

    # Default: passthrough to resticprofile
    if command:
        run_resticprofile(command, *args)
    else:
        run_resticprofile()


# endregion

if __name__ == "__main__":
    main()
