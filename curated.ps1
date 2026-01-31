<#
Curated front door (PowerShell 7)

Usage:
  pwsh ./curated.ps1 setup
  pwsh ./curated.ps1 scan
  pwsh ./curated.ps1 doctor
  pwsh ./curated.ps1 governance
  pwsh ./curated.ps1 release -Version 1.0.0
  pwsh ./curated.ps1 gen-rules
  pwsh ./curated.ps1 new -Name <ProjectName> [-RunDoctor]
  pwsh ./curated.ps1 test
#>

param(
  [Parameter(Position=0)]
  [ValidateSet("setup","scan","doctor","governance","release","gen-rules","test","new","help")]
  [string]$Command = "help",

  # release-only
  [string]$Version = "1.0.0",
  [string]$GitHubToken,
  [string]$Repo = "moarbetsy/setup-cursor",

  # new: project name and optional doctor
  [string]$Name,
  [switch]$RunDoctor
)

$ErrorActionPreference = "Stop"

function Here($p) { Join-Path $PSScriptRoot $p }

switch ($Command) {
  "setup" {
    & (Here "packages\setup-cursor\run.ps1") -Setup
  }
  "scan" {
    Push-Location (Here "packages\precursor")
    try {
      if (Test-Path "package.json") {
        if (Test-Path "bun.lock") {
          bun install --frozen-lockfile
        } else {
          bun install
        }
      }
      bun run src/cli.ts scan --json
    } finally {
      Pop-Location
    }
  }
  "doctor" {
    Push-Location (Here "packages\precursor")
    try {
      if (Test-Path "package.json") {
        if (Test-Path "bun.lock") {
          bun install --frozen-lockfile
        } else {
          bun install
        }
      }
      bun run src/cli.ts setup
    } finally {
      Pop-Location
    }
  }
  "governance" {
    $govScript = (Here "templates\governance\scripts\doctor.ps1")
    if (-not (Test-Path $govScript)) {
      Write-Host "Governance template doctor not found: $govScript" -ForegroundColor Red
      exit 1
    }
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $govScript
  }
  "gen-rules" {
    $scriptPath = (Here "scripts\gen-rules.ps1")
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath
  }
  "test" {
    $scriptPath = (Here "scripts\gen-rules.ps1")
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Check
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Push-Location (Here "packages\precursor")
    try {
      if (Test-Path "package.json") {
        if (Test-Path "bun.lock") { bun install --frozen-lockfile } else { bun install }
      }
      bun test
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      bun run src/cli.ts check-rules
    } finally {
      Pop-Location
    }
    Push-Location (Here "packages\setup-cursor")
    try {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File (Here "packages\setup-cursor\test-setup.ps1")
    } finally {
      Pop-Location
    }
  }
  "release" {
    Push-Location (Here "packages\setup-cursor")
    try {
      & .\create-release.ps1 -Version $Version -GitHubToken $GitHubToken -Repo $Repo
    } finally {
      Pop-Location
    }
  }
  "new" {
    if (-not $Name) {
      Write-Host "new requires -Name <ProjectName>. Example: pwsh ./curated.ps1 new -Name MyProject -RunDoctor" -ForegroundColor Red
      exit 1
    }
    $newProjectScript = Here "scripts\new-project.ps1"
    $newArgs = @("-Name", $Name, "-CuratedRoot", $PSScriptRoot)
    if ($RunDoctor) { $newArgs += "-RunDoctor" }
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $newProjectScript @newArgs
    exit $LASTEXITCODE
  }
  default {
    Write-Host @"
Curated front door

Commands:
  setup   - run setup-cursor (Windows onboarding)
  scan    - run Precursor scan (JSON diagnostics)
  doctor  - run Precursor setup/doctor
  governance - run governance template doctor (templates/governance)
  gen-rules - regenerate Cursor rules from rules-src
  test    - run rules check + Precursor unit tests + check-rules + setup-cursor diagnostic
  new     - create project from governance template with .cursor and Precursor; optionally run doctor
  release - build setup-cursor zip (bundles Precursor)

Examples (run from repo root):
  pwsh ./curated.ps1 scan
  pwsh ./curated.ps1 gen-rules
  pwsh ./curated.ps1 test
  pwsh ./curated.ps1 new -Name MyProject -RunDoctor
  pwsh ./curated.ps1 release -Version 1.0.1

  From packages\precursor (one command):
  pwsh ..\..\curated.ps1 gen-rules

  From packages\precursor (two commands, use ; not "then"):
  cd ..\..; pwsh ./curated.ps1 gen-rules
"@
  }
}
