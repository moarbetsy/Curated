---
description: Python toolchain (uv, ruff, pyright)
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
  - "uv.lock"
---

# Python Development Rules

## Toolchain
- Runtime / env: **uv**
- Linter + formatter: **ruff**
- Type checker: **pyright**

## Commands
- Install/sync: `uv sync`
- Run: `uv run <command>`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `pyright .`

## Virtual environment
- Standard path: `.venv`
- IDE should point to the venv interpreter (don’t use system Python).
