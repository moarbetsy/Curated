# Copy-paste commands

Run these from PowerShell. If your execution policy blocks scripts, use the `pwsh -NoProfile -ExecutionPolicy Bypass -File ...` form.

---

## From repo root (after clone/cd into Curated)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 setup
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 scan
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 doctor
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 governance
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 gen-rules
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new -Name MyProject -RunDoctor
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 release -Version 1.0.0
```

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 help
```

---

## After bootstrap (Curated at `$env:USERPROFILE\Curated`)

**Test (single command):**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\curated.ps1" test
```

**Self-test (no cd):**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\scripts\self-test.ps1"
```

**New project:**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\curated.ps1" new -Name MyProject -RunDoctor
```

**Any command (replace `<command>` with setup, scan, doctor, gen-rules, test, etc.):**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Curated\curated.ps1" <command>
```

---

## Bootstrap (fresh Windows)

Replace `<OWNER>` and `<REPO>` with your GitHub org/repo.

**One-liner (download + run).** Uses a path variable; outer string is single-quoted so inner pwsh expands $f and $env:TEMP ('' = escaped single quote):
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command '& { $f = Join-Path $env:TEMP ''bootstrap.ps1''; Invoke-WebRequest -Uri ''https://raw.githubusercontent.com/<OWNER>/<REPO>/main/scripts/bootstrap.ps1'' -OutFile $f -UseBasicParsing; & pwsh -NoProfile -ExecutionPolicy Bypass -File $f -RepoUrl ''https://github.com/<OWNER>/<REPO>'' -Ref main }'
```

**If you already have the repo (from repo root):**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\scripts\bootstrap.ps1" -RepoUrl "https://github.com/<OWNER>/<REPO>" -Ref main
```

**Bootstrap + create new project:**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\scripts\bootstrap.ps1" -RepoUrl "https://github.com/<OWNER>/<REPO>" -Ref main -NewProjectName MyProject
```

---

## Gen-rules only (from repo root)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\gen-rules.ps1
```

---

## Slash commands (Precursor)

Slash commands are defined in `packages/precursor/precursor.json` or `.precursor/commands/*.json`.

Available in this repo:
- `/apply-report` — lists unresolved/mitigated entries in `docs/REPORT.md` and prints a remediation checklist (`.precursor/commands/apply-report.json`).
