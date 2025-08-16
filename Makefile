# Makefile - Poetry-based development commands
.PHONY: install dev lint format type-check clean build publish

install:
	poetry install

dev:
	poetry install --with dev
	poetry run pre-commit install

lint:
	poetry run ruff check .

format:
	poetry run ruff format .

type-check:
	poetry run mypy rv.py

check: lint type-check

clean:
	rm -rf build/ dist/ *.egg-info/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	poetry env remove --all

build:
	poetry build

publish:
	poetry publish

shell:
	poetry shell

# Development workflow shortcuts
fix:
	poetry run ruff check . --fix
	poetry run ruff format .

ci: install check
	@echo "✅ All checks passed!"
