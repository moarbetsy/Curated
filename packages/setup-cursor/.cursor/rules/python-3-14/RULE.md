---
description: Extra guidance only when the user explicitly targets Python 3.14.
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Python 3.14 addendum (only if explicitly requested)

- Apply this rule only when the user targets Python 3.14; otherwise follow `python.mdc`.
- See `docs/PYTHON_3_14.md` for 3.14-specific guidance.
- Default tooling remains uv + ruff + pyright unless project config says otherwise.
