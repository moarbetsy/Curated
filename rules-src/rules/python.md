---
description: Python toolchain and common commands (uv, ruff, pyright).
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
  - "uv.lock"
---

# Python

- Follow the project's configured Python version.
- Tooling: uv (env/runtime), ruff (lint/format), pyright (type check).
- Commands:
  - `uv sync`
  - `uv run <command>`
  - `ruff check .`
  - `ruff format .`
  - `pyright .`
- Use `.venv` as the virtual environment path; point the IDE to it.
