"""Main function with command dispatch."""

import sys
import argparse
from typing import Optional

from rv.commands import COMMANDS
from rv.utils import run_resticprofile, with_password


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
        with_password(run_resticprofile)(*sys.argv[1:])
        return

    # Check if it's a custom command
    if command in COMMANDS:
        COMMANDS[command](args)
        return

    # Default: passthrough to resticprofile
    if command:
        with_password(run_resticprofile)(command, *args)
    else:
        with_password(run_resticprofile)()
