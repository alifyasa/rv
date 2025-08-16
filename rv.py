#!/usr/bin/env python3
"""
rv - Versioning using Restic
"""

import os
import sys
import subprocess
import getpass
import shutil
from pathlib import Path

# region Utilities


def find_restic_dir() -> Path | None:
    """Find .restic directory by walking up from current directory"""
    current = Path.cwd()
    for parent in [current, *current.parents]:
        restic_dir = parent / ".restic"
        if restic_dir.is_dir():
            return restic_dir
    return None


def load_config(restic_dir: Path) -> None:
    """Load environment variables from .restic/config"""
    config_file = restic_dir / "config"
    if not config_file.exists():
        print(f"Error: {config_file} not found", file=sys.stderr)
        sys.exit(1)

    # Read and execute the config file to set environment variables
    with open(config_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                if line.startswith("export "):
                    line = line[7:]  # Remove 'export '
                if "=" in line:
                    key, value = line.split("=", 1)
                    # Remove quotes if present
                    value = value.strip("\"'")
                    os.environ[key] = value


def run_restic(args: list[str]) -> None:
    """Run restic with the given arguments"""
    cmd = ["restic"] + args
    os.execvp("restic", cmd)


# endregion

# region Commands


def cmd_init(args: list[str]) -> None:
    """Initialize a new restic repository"""
    restic_dir = Path(".restic")

    if restic_dir.exists():
        print("Error: .restic directory already exists")
        sys.exit(1)

    try:
        # Create directory structure
        repo_dir = restic_dir / "repo"
        repo_dir.mkdir(parents=True)

        # Create config file
        config_content = (
            'export RESTIC_REPOSITORY=".restic/repo"\n'
            'export RESTIC_PASSWORD_FILE=".restic/password"\n'
        )
        (restic_dir / "config").write_text(config_content)

        # Get password
        while True:
            password = getpass.getpass("Enter password for new repository: ")
            password2 = getpass.getpass("Enter password again: ")
            if password == password2:
                break
            print("Error: Passwords don't match")

        # Save password
        password_file = restic_dir / "password"
        password_file.write_text(password)
        password_file.chmod(0o600)

        # Load config and initialize repository
        load_config(restic_dir)

        # Initialize restic repository
        result = subprocess.run(["restic", "init"] + args, check=False)
        if result.returncode == 0:
            print("Initialized restic repository in .restic/")
        else:
            # Restic init failed, clean up
            if restic_dir.exists():
                shutil.rmtree(restic_dir)
        sys.exit(result.returncode)
    except (OSError, IOError, PermissionError, KeyboardInterrupt) as e:
        # Clean up on any error
        if restic_dir.exists():
            shutil.rmtree(restic_dir)
        print(f"Error during initialization: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_status(args: list[str]) -> None:
    """Show recent snapshots (like git status)"""
    restic_dir = find_restic_dir()
    if restic_dir is None:
        print("Error: not in a restic repository (no .restic found)", file=sys.stderr)
        sys.exit(1)

    load_config(restic_dir)
    print("Recent snapshots:")
    run_restic(["snapshots", "--compact", "--last", "5"] + args)


def cmd_log(args: list[str]) -> None:
    """Show all snapshots (like git log)"""
    restic_dir = find_restic_dir()
    if restic_dir is None:
        print("Error: not in a restic repository (no .restic found)", file=sys.stderr)
        sys.exit(1)

    load_config(restic_dir)
    run_restic(["snapshots"] + args)


# endregion

# region Command Dispatch

# Command registry - add new commands here
COMMANDS = {
    "init": cmd_init,
    "status": cmd_status,
    "log": cmd_log,
    # Add more commands here...
}


def main() -> None:
    """Main function with command dispatch"""
    # Get command (first argument)
    command = sys.argv[1] if len(sys.argv) > 1 else None
    args = sys.argv[2:] if len(sys.argv) > 2 else []

    # Check if it's a custom command
    if command in COMMANDS:
        COMMANDS[command](args)
        return

    # Default: passthrough to restic
    restic_dir = find_restic_dir()
    if restic_dir is None:
        print("Error: not in a restic repository (no .restic found)", file=sys.stderr)
        sys.exit(1)

    # Load configuration and pass through to restic
    load_config(restic_dir)
    run_restic(sys.argv[1:])


# endregion

if __name__ == "__main__":
    main()
