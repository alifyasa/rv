"""Get password using getpass and print it back."""

import sys
import getpass


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
