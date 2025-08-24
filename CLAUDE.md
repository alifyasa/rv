# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Codebase Constraints
**CRITICAL**:
1. This codebase is constrained to use Python 3.9 standard libraries only. Do not suggest or add any external dependencies beyond what's already in pyproject.toml.
2. All code must be fully typed with type hints. Run `make type-check` to verify mypy compliance before any changes.
3. Use global imports (not relative imports) to ensure PyInstaller compatibility.

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
make type-check   # Run mypy type checking on rv/ package
make check        # Run both lint and type-check
make fix          # Auto-fix linting issues and format code
make ci           # Full CI pipeline (install + check)
```

### Build and Publishing
```bash
make build        # Build package with poetry
make build-exe    # Build standalone executable with PyInstaller (platform-specific)
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

1. **Configuration Management** (`rv/config.py`): Constants and templates for Restic repository configuration, including CONFIG_DIR and CONFIG_TEMPLATE.

2. **Repository Discovery** (`rv/utils.py`): Utility functions including `find_restic_dir()` which walks up directory tree to find `.rv` directory, and `run_resticprofile()` for executing resticprofile commands.

3. **Command System** (`rv/commands/__init__.py`): Registry-based command dispatch with COMMANDS dictionary that maps custom commands to handler functions, with fallback passthrough to native Restic commands.

4. **Custom Commands**:
   - `init` (`rv/commands/init.py`): Creates `.rv/` directory structure, prompts for password, initializes Restic repository
   - `log` (`rv/commands/log.py`): Shows recent snapshots (Git log equivalent)
   - `get-pass` (`rv/commands/get_pass.py`): Password handling utility

5. **CLI Entry Point** (`rv/main.py`): Main function with argument parsing and command dispatch logic.

### File Structure
```
rv/                          # Main package directory
├── __init__.py              # Package marker with version info
├── __main__.py              # Entry point for 'python -m rv'
├── main.py                  # CLI argument parsing and command dispatch
├── config.py                # Configuration constants and templates
├── utils.py                 # Repository discovery and resticprofile utilities
└── commands/                # Command implementations
    ├── __init__.py          # Command registry (COMMANDS dictionary)
    ├── base.py              # Command type definitions
    ├── init.py              # 'rv init' command implementation
    ├── log.py               # 'rv log' command implementation
    └── get_pass.py          # 'rv get-pass' command implementation

generate_spec.py             # Generates PyInstaller spec with git commit hash
rv.spec                      # PyInstaller specification (auto-generated)
dist/rv                      # Standalone executable (platform-specific)

.rv/                         # Created by 'rv init' in project directories
├── config.yaml              # Resticprofile configuration
├── .rvignore                # Exclude patterns
└── repo/                    # Actual Restic repository data
```

### Extension Pattern
New commands are added by:
1. Create a new file `rv/commands/new_command.py` with a `cmd_new_command()` function that takes `args: list[str]`
2. Import the function in `rv/commands/__init__.py`
3. Add entry to `COMMANDS` dictionary in `rv/commands/__init__.py`
4. Commands should use `find_restic_dir()` and `run_resticprofile()` from `rv.utils` for consistency
5. Use global imports: `from rv.utils import find_restic_dir` (not relative imports)

All unrecognized commands are passed through directly to the underlying resticprofile binary after loading configuration.

## CI/CD

The project includes GitHub Actions workflows:

### Continuous Integration (`.github/workflows/ci.yml`)
- Runs on every push/PR to main branch
- Validates code with mypy type checking and ruff linting
- Tests executable build process
- Runs on Ubuntu latest with Python 3.9

### Build and Release (`.github/workflows/build-release.yml`)
- Triggers on git tags (v*) or manual workflow dispatch
- Builds executables for both Linux amd64 and Windows amd64
- Runs full CI pipeline (type check, lint) before building
- Creates GitHub releases with platform-specific executables attached
- Artifacts: `rv-linux-amd64` and `rv-windows-amd64.exe`

### Creating a Release
1. Tag your commit: `git tag v1.0.0 && git push origin v1.0.0`
2. GitHub Actions will automatically build and create a release
3. Executables will be attached to the release for download
