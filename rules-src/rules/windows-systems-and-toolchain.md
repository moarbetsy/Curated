---
description: Windows + PowerShell 7 environment, toolchain contract, and run entrypoints.
alwaysApply: true
---

# Windows systems and toolchain

## Environment assumptions
- OS: Windows 11 (x64).
- Shell: PowerShell 7 (`pwsh -NoProfile -NoLogo`).
- Hardware baseline: Intel i7-8665U / 16GB RAM; favor low overhead.

## PowerShell-only
- Output PowerShell 7 syntax only.
- Never output Bash commands or operators (`ls`, `rm -rf`, `&&`, `||`).
- Use `;` or `if ($?) { ... }` instead of `&&`.
- Use `if (-not $?) { ... }` instead of `||`.
- Use Windows paths with `\` or `Join-Path`.

## Encoding
- In any PowerShell script you create or modify, set:
  `[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()`

## Process management
- Do not leave background processes running indefinitely.
- Stop processes by PID and explain what is being terminated.
- Avoid broad `Stop-Process -Name` unless explicitly requested.

## Toolchain contract
- Python: uv only. Never use `pip install` or `python -m venv`.
  - `uv init`, `uv add <package>`, `uv sync`, `uv run <command>`
- JavaScript: bun only. Never use npm or yarn unless forced by legacy deps.
  - `bun install`, `bun run <script>`, `bunx <tool>`
- Node.js is runtime-only; do not use it as a package manager.

## Execution strategy (single entry point)
- Use `curated.ps1` as the entry point in this repo; do not add a new `run.ps1` here.
- For new repos or templates, create or update a root `run.ps1` and route execution through it.

## run.ps1 requirements (when used)
- Idempotent and safe to re-run; fail fast with clear errors.
- Include tool preflight checks via `Get-Command` and show `where.exe` output on failure.
- Avoid indefinite watchers; if needed, bound execution and document how to stop.

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
```

## Troubleshooting defaults
- Verify tool visibility: `where.exe <tool>` and `Get-Command <tool> -ErrorAction SilentlyContinue`.
- If scripts are blocked, suggest `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`.
- Exit code `0xFFFFFFFF` indicates a silent crash; capture stdout/stderr to a log file and show the tail.
