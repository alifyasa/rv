"""Command registry and discovery."""

from typing import Dict, Callable

from rv.commands.init import cmd_init
from rv.commands.log import cmd_log
from rv.commands.get_pass import cmd_get_pass

# Command registry - add new commands here
COMMANDS: Dict[str, Callable[[list[str]], None]] = {
    "init": cmd_init,
    "log": cmd_log,
    "get-pass": cmd_get_pass,
}
