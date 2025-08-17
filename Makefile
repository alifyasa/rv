# Makefile - uv-based development commands
.PHONY: install dev lint format type-check clean

install:
	uv sync

dev:
	uv sync --with dev
	uv run pre-commit install

lint:
	uv run ruff check .

format:
	uv run ruff format .

type-check:
	uv run mypy rv.py

check: lint type-check

clean:
	rm -rf build/ dist/ *.egg-info/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	uv env remove --all

# Development workflow shortcuts
fix:
	uv run ruff check . --fix
	uv run ruff format .

ci: install check
	@echo "✅ All checks passed!"
