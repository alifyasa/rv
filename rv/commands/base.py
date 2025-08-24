"""Base types for command handlers."""

from typing import Protocol


class CommandHandler(Protocol):
    """Protocol for command handler functions."""

    def __call__(self, args: list[str]) -> None:
        """Execute the command with the given arguments."""
        ...
