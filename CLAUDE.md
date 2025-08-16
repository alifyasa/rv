# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Codebase Constraints
**CRITICAL**:
1. This codebase is constrained to use Python 3.9 standard libraries only. Do not suggest or add any external dependencies beyond what's already in pyproject.toml.
2. One file only (rv.py) - all functionality must remain in the single file. Use VS Code style region markers (`# region` / `# endregion`) to organize code sections.

## Development Commands

### Setup and Installation
```bash
make dev          # Install dev dependencies and setup pre-commit hooks
make install      # Install base dependencies only
```

### Code Quality
```bash
make lint         # Run ruff linting
make format       # Auto-format code with ruff
make type-check   # Run mypy type checking on rv.py
make check        # Run both lint and type-check
make fix          # Auto-fix linting issues and format code
make ci           # Full CI pipeline (install + check)
```

### Build and Publishing
```bash
make build        # Build package with poetry
make publish      # Publish to PyPI
make clean        # Remove build artifacts and caches
```

### Development Environment
```bash
make shell        # Activate poetry shell
```

## Architecture Overview

rv is a Git-like wrapper around Restic backup tool that provides familiar version control commands for file versioning. The architecture follows a simple command dispatch pattern:

### Core Components

1. **Configuration Management** (`rv.py:29-48`): Loads environment variables from `.rv/config` file to configure Restic repository settings.

2. **Repository Discovery** (`rv.py:19-26`): Walks up directory tree to find `.rv` directory, similar to Git's `.git` discovery.

3. **Command System** (`rv.py:138-144`): Registry-based command dispatch that maps custom commands to handler functions, with fallback passthrough to native Restic commands.

4. **Custom Commands**:
   - `init`: Creates `.rv/` directory structure, prompts for password, initializes Restic repository
   - `status`: Shows recent 5 snapshots (Git status equivalent)
   - `log`: Shows all snapshots (Git log equivalent)

### File Structure
- `rv.py`: Single-file application containing all functionality
- `.rv/config`: Environment variables for Restic configuration
- `.rv/password`: Repository password file (created during init)
- `.rv/repo/`: Actual Restic repository data

### Extension Pattern
New commands are added by:
1. Creating a `cmd_<name>()` function that takes `args: list[str]`
2. Adding entry to `COMMANDS` dictionary (`rv.py:139-144`)
3. Commands should call `find_restic_dir()` and `load_config()` before using Restic

All unrecognized commands are passed through directly to the underlying Restic binary after loading configuration.
