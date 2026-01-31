# Python 3.14 addendum

Use this only when the project explicitly targets Python 3.14.

## Tooling
- Runtime/env: uv
- Lint/format: ruff
- Type checking: pyright by default (use mypy only if the project config says so)
- Prefer pyproject.toml for configuration

## Type annotations (PEP 649 / 749)
- Always annotate functions, methods, and public attributes.
- Do not assume __annotations__ contains resolved values.
- When inspecting types at runtime, use:
  annotationlib.get_annotations(obj, format=annotationlib.Format.VALUE)
- Avoid "from __future__ import annotations" if 3.14 semantics are active.

## Concurrency and parallelism
- Default: use asyncio for I/O-bound tasks.
- Free-threading (PEP 703):
  - For CPU-bound contexts, consider the free-threaded (no-GIL) build.
  - Prefer thread-safe data structures (queue.Queue over manual locking).
  - Verify imported C-extensions (NumPy, etc.) are compatible with free-threading.
- Subinterpreters (PEP 734):
  - Use concurrent.interpreters only for strict component isolation or actor-model architectures.
  - Pass data between interpreters using serialized messages (JSON/bytes), never shared mutable objects.

## String and security (PEP 750)
- Use template string literals for structured DSLs (SQL/HTML/etc.) where appropriate.
- Avoid ad-hoc string concatenation (+ or f-strings) for SQL queries or shell commands.

## Error handling and control flow
- Use specific exception types; never `except Exception:`.
- Use `except*` only when handling ExceptionGroup from concurrent tasks.
- Prefer structured logging with tracebacks over print.

## Performance and libraries
- Prefer compression.zstd over gzip or zipfile for internal data processing if available.
- Use asyncio introspection tools to identify leaked tasks in long-running services.

## Code style
- Keep business logic decoupled from I/O (HTTP, CLI, DB).
- Follow strict PEP 8 naming conventions.
- Prefer immutable data structures (frozen dataclasses) to simplify thread safety.

## Execution contract (this repo)
- Use uv for environments and execution:
  - uv sync
  - uv run <command>
- Do not recommend pip install or python -m venv.