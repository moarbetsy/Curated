# Setup Prompt: Add Precursor Rules

Use this prompt to set up the Precursor rules in a new workspace.

## Prompt Text

```
Set up the following Cursor rules for this workspace:

### 1. Create .cursor/rules directory structure

Create the following rule files in `.cursor/rules/`:

#### windows-systems-and-toolchain.mdc
```markdown
---
description: Windows PowerShell 7, uv, and Bun rules for stable, reproducible automation
alwaysApply: true
---

# Role and environment
- Role: Windows Systems and Automation Expert
- OS: Windows 11 (x64)
- Shell: PowerShell 7 (pwsh)
- Terminal assumption: `pwsh -NoLogo -NoProfile`
- Hardware: Intel i7-8665U / 16GB RAM (optimize for low overhead and speed)

# Hard constraints
## PowerShell syntax only
- Always output PowerShell 7 syntax.
- Never output Bash commands (ls, touch, export, source, rm -rf).
- Never use bash operators && or ||.
  - Use ";" or "if ($?) { ... }" instead of "&&".
  - Use "if (-not $?) { ... }" instead of "||".
- Use Windows paths with "\" or Join-Path.

## Encoding
In any PowerShell script you create or modify, force UTF-8 output encoding:
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

## Process management
- Do not leave background processes running indefinitely.
- If stopping processes, target specific PIDs and explain what is being terminated.
- Do not use broad Stop-Process by name unless explicitly requested.

# Toolchain contract
## Python (uv only)
- Never use "pip install" or "python -m venv".
- Use uv:
  - Init: uv init
  - Add deps: uv add <package>
  - Sync: uv sync
  - Run: uv run <command>

## JavaScript (Bun only)
- Never use npm or yarn unless explicitly forced by a legacy dependency.
- Use bun:
  - Install: bun install
  - Run: bun run <script>
  - Tooling: bunx <tool>

## Node.js
Use Node.js only as a runtime requirement when needed; do not use it as a package manager.

# Execution strategy: single entry point (mandatory)
- Do not ask the user to type many loose commands.
- For this repo, use `curated.ps1` as the single entry point; do not add a new run.ps1 here.
- For project templates or new repos, create/update a run.ps1 in the repo root and route execution through it.

## run.ps1 requirements (when a run.ps1 is used)
- Must be idempotent and safe to re-run.
- Must fail fast with clear errors.
- Must include tool preflight checks via Get-Command and include where.exe diagnostics on failure.
- Avoid indefinite watchers. If a watcher is unavoidable, provide bounded execution and a clean stop mechanism.

## Standard run.ps1 template
```powershell
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Write-Host "Preflight checks..." -ForegroundColor Cyan

$tools = @("pwsh") # add "uv" and/or "bun" per project
foreach ($t in $tools) {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
        Write-Host "Missing tool: $t" -ForegroundColor Red
        Write-Host ("PATH check: " + (where.exe $t 2>$null)) -ForegroundColor Yellow
        exit 1
    }
}

# Python (uv):
# if (Test-Path "pyproject.toml") { uv sync; if ($?) { uv run python main.py } }

# JavaScript (bun):
# if (Test-Path "package.json") { bun install; if ($?) { bun run start } }
```

# Troubleshooting defaults

* On failure, do not assume code is wrong first.
* Verify tool visibility:
  * where.exe <tool>
  * Get-Command <tool> -ErrorAction SilentlyContinue
* If scripts are blocked, suggest:
  * Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
* If exit code is 0xFFFFFFFF, treat as a silent crash. Capture stdout/stderr to a log file and print the tail.

# Diagnostics and self-healing

* **Command Not Found**: Run `setup-cursor -Setup` (or `sc -Setup`) if available
* **Terminal Hangs**: Switch to Windows Terminal to isolate issues
* **Tool spawn failures**: Retry once; if persistent, check PATH and execution policy
```

#### issue-reporting-and-apply-report.mdc
```markdown
---
description: Issue reporting + apply report entry point
alwaysApply: true
---

# Issue reporting (mandatory)
Follow `docs/AGENT_PROTOCOL.md` section 4 for what and how to log. Append to `docs/REPORT.md` only (no secrets).

# Apply report
Use `/apply-report` (defined in `.precursor/commands/apply-report.json`) to list unresolved/mitigated entries and follow its remediation checklist.
```

#### diagnostics.mdc
```markdown
---
description: Self-healing diagnostics for common workspace issues
alwaysApply: false
---

# Diagnostics

See `docs/AGENT_PROTOCOL.md` (Failure Loop) and `windows-systems-and-toolchain.mdc` for the authoritative workflow.

Quick pointers for common issues:

- **Command Not Found**: Run `setup-cursor -Setup` (or `sc -Setup`) if available
- **Terminal Hangs**: Switch to Windows Terminal to isolate issues
```

#### python.mdc
```json
{
  "content": "# Python Development Rules\n\n## Toolchain\n- Runtime: uv\n- Linter: ruff\n- Formatter: ruff\n- Type Checker: pyright\n\n## Commands\n- Install: `uv sync`\n- Lint: `ruff check .`\n- Format: `ruff format .`\n- Type Check: `pyright .`\n\n## Virtual Environment\n- Path: `.venv`\n- Activate: `.\\.venv\\Scripts\\activate` (Windows) or `source .venv/bin/activate` (Unix)\n"
}
```

#### web.mdc
```json
{
  "content": "# Web/JS/TS Development Rules\n\n## Toolchain\n- Runtime: bun\n- Linter: biome\n- Formatter: biome\n- Type Checker: tsc\n\n## Commands\n- Install: `bun install`\n- Lint: `bunx biome check .`\n- Format: `bunx biome format --write .`\n- Type Check: `bunx tsc --noEmit`\n\n## Lockfile\n- Prefer: `bun.lock` (text format)\n- Legacy: `bun.lockb` (binary, accepted but not preferred)\n"
}
```

#### python-3-14.mdc
```markdown
---
description: Python 3.14 addendum (only when explicitly targeted)
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Python 3.14 addendum (optional)
Only apply when the user explicitly targets Python 3.14. Otherwise follow `python.mdc`.

See `docs/PYTHON_3_14.md` for advanced guidance. Tooling defaults remain: uv + ruff + pyright (unless project config says otherwise).
```

### 2. Verify Setup

After creating the files:
1. Ensure `.cursor/rules/` directory exists with all rule files
2. Restart Cursor to load the new rules

The rules will be automatically applied based on their `alwaysApply` settings and glob patterns.
```

## Usage

Copy the prompt text above and paste it into Cursor when setting up a new workspace. The AI assistant will create all the necessary rule files.

## Notes

- The `windows-systems-and-toolchain.mdc` and `issue-reporting-and-apply-report.mdc` rules have `alwaysApply: true`, so they will always be active.
- The `python-3-14.mdc` rule applies only to Python files and `pyproject.toml` based on its glob patterns.
- The `python.mdc` and `web.mdc` files are JSON-formatted rule files.
- Node.js is included as a runtime option in the toolchain contract.
