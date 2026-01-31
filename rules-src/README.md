# rules-src (single source of truth)

Edit rule content here.

Then regenerate outputs:

- PowerShell (Windows users with strict policy: use this so scripts run):
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\gen-rules.ps1
  ```
- Otherwise: `pwsh ./scripts/gen-rules.ps1`

Run **gen-rules before doctor/scan** so the rules gate and Precursor scan stay clean when pushing to CI.

Outputs written:
- Repo-wide rules: `.cursor/rules/*.mdc` and `.cursor/rules/INCIDENTS.md`
- setup-cursor package rules: `packages/setup-cursor/.cursor/rules/**/RULE.md`
- precursor package rules: `packages/precursor/.cursor/rules/*.mdc` and `packages/precursor/.cursor/rules/**/RULE.md`

CI-friendly drift check:
- `pwsh ./scripts/gen-rules.ps1 -Check`
