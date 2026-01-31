# Curated (New-Pre-Cursor)

Curated is a **Cursor-first dev environment kit** with three components:

- **setup-cursor** (`packages/setup-cursor/`): Windows onboarding + tool install + sane editor defaults.
- **precursor** (`packages/precursor/`): project doctor/scaffolder + CI diagnostics (scan) via a TS CLI.
- **governance template** (`templates/governance/`): repo contract (lockfile law, single CI entrypoint, “one rewriter per extension”).

## Quick links
- Protocol + audit docs: `docs/AGENT_PROTOCOL.md`, `docs/STEPLOG.md`, `docs/REPORT.md`, `docs/PATCH_RUNBOOK.md`
- Precursor CI workflow: `.github/workflows/precursor.yml`
- Copy-paste commands: `docs/COMMANDS.md`
- Publish to GitHub (bootstrap-ready): `docs/PUBLISH.md`

---

## Quick start (fresh Windows)

On a clean Windows machine (with **winget** installed; install App Installer from Microsoft Store if needed), run the bootstrap script from a raw URL. It installs tools via winget, downloads Curated to a path without spaces (default `$env:USERPROFILE\Curated`), **restarts once** so PATH updates take effect, then runs gen-rules, doctor, and scan. Optionally creates a new project.

**One-liner (replace `<OWNER>` and `<REPO>` with your GitHub org/repo; run in PowerShell).** Uses a path variable so the inner pwsh expands the path:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command '& { $f = Join-Path $env:TEMP ''bootstrap.ps1''; Invoke-WebRequest -Uri ''https://raw.githubusercontent.com/<OWNER>/<REPO>/main/scripts/bootstrap.ps1'' -OutFile $f -UseBasicParsing; & pwsh -NoProfile -ExecutionPolicy Bypass -File $f -RepoUrl ''https://github.com/<OWNER>/<REPO>'' -Ref main }'
```

Or download `scripts/bootstrap.ps1` and run:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\scripts\bootstrap.ps1" -RepoUrl "https://github.com/<OWNER>/<REPO>" -Ref main
```

Optional: create a new project right after bootstrap:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\scripts\bootstrap.ps1" -RepoUrl "https://github.com/<OWNER>/<REPO>" -Ref main -NewProjectName MyProject
```

The script restarts once so PATH (pwsh, bun, etc.) is visible before gen-rules/doctor/scan.

**Single test command** (after bootstrap; Curated is at `$env:USERPROFILE\Curated` by default):
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\curated.ps1" test
```

Or use self-test (no need to cd into Curated):
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\scripts\self-test.ps1"
```

**New project** (from governance template + .cursor + Precursor; optional doctor):
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\curated.ps1" new -Name MyProject -RunDoctor
```

Default paths: install path `$env:USERPROFILE\Curated`, new projects under `$env:USERPROFILE\Projects`.

### Path and execution policy

- Use **quoted paths** for paths that may contain spaces or parentheses (e.g. `"$env:USERPROFILE\Curated\curated.ps1"`).
- Use **process-level** `-ExecutionPolicy Bypass` (e.g. `pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1`); no system policy change is required.

---

## Canonical layout
- `packages/` contains **shippable code** (single source of truth).
- `templates/` contains **project templates**.
- `docs/` contains **protocol + audit trail**.
- Root `.cursor/` contains **repo-wide Cursor rules**.

## Rules single source of truth
Edit Cursor rule content in `rules-src/` and regenerate outputs:
- `pwsh ./curated.ps1 gen-rules`

**Windows (strict execution policy):** run scripts like this so policy doesn’t block:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 <command>
```
Run **gen-rules before doctor/scan** so the rules gate and Precursor scan stay clean:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\gen-rules.ps1
```

Generated outputs:
- Repo-wide: `.cursor/rules/*.mdc` and `.cursor/rules/INCIDENTS.md`
- setup-cursor: `packages/setup-cursor/.cursor/rules/**/RULE.md`
- precursor: `packages/precursor/.cursor/rules/*.mdc` and `packages/precursor/.cursor/rules/**/RULE.md`

## Compatibility
Older paths like `machine-setup/` were consolidated under `packages/setup-cursor/`.

## List of commands

| Command | Description |
|--------|-------------|
| `setup` | Run setup-cursor (Windows onboarding) |
| `scan` | Run Precursor scan (JSON diagnostics) |
| `doctor` | Run Precursor setup/doctor |
| `governance` | Run governance template doctor (`templates/governance`) |
| `gen-rules` | Regenerate Cursor rules from `rules-src/` |
| `test` | Rules check + Precursor unit tests + check-rules + setup-cursor diagnostic |
| `new -Name <ProjectName> [-RunDoctor]` | Create project from governance template with .cursor and Precursor; optionally run doctor |
| `release -Version <ver>` | Build setup-cursor zip (bundles Precursor) |
| `help` | Show this list (default) |

**Entrypoint:** `pwsh ./curated.ps1 <command>`. On Windows with a strict execution policy: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 <command>`.
