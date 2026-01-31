<#
.SYNOPSIS
  Create a new project from templates/governance with Curated .cursor and Precursor; optionally run doctor.

.DESCRIPTION
  Copies templates/governance to destination, .cursor from Curated root, and packages/precursor to project-doctor.
  Then git init; optionally -RunDoctor runs bun install and bun run src/cli.ts setup in project-doctor.
  Default destination parent: $env:USERPROFILE\Projects. All paths quoted.

.PARAMETER Name
  Project name (required).

.PARAMETER DestRoot
  Parent directory for the new project (default: $env:USERPROFILE\Projects).

.PARAMETER RunDoctor
  After copy, run doctor in project-doctor (bun install, bun run src/cli.ts setup).

.PARAMETER CuratedRoot
  Curated repo root (default: parent of scripts/, i.e. $PSScriptRoot\.. when run from repo).
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Name,

  [string]$DestRoot = (Join-Path $env:USERPROFILE "Projects"),

  [switch]$RunDoctor,

  [string]$CuratedRoot
)

$ErrorActionPreference = "Stop"

if (-not $CuratedRoot) {
  $CuratedRoot = Split-Path -Parent $PSScriptRoot
}

$dest = Join-Path $DestRoot $Name
if (Test-Path -LiteralPath $dest) {
  Write-Host "Destination already exists: $dest" -ForegroundColor Red
  exit 1
}

$govTemplate = Join-Path $CuratedRoot "templates\governance"
if (-not (Test-Path $govTemplate)) {
  Write-Host "Governance template not found: $govTemplate" -ForegroundColor Red
  exit 1
}

Write-Host "Creating project: $Name at $dest" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Copy governance template (exclude .git if present)
Get-ChildItem -LiteralPath $govTemplate -Force | Where-Object { $_.Name -ne ".git" } | ForEach-Object {
  $target = Join-Path $dest $_.Name
  if ($_.PSIsContainer) {
    Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
  } else {
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
  }
}

# Copy .cursor from Curated root
$cursorSrc = Join-Path $CuratedRoot ".cursor"
$cursorDest = Join-Path $dest ".cursor"
if (Test-Path $cursorSrc) {
  if (-not (Test-Path $cursorDest)) {
    New-Item -ItemType Directory -Path $cursorDest -Force | Out-Null
  }
  Get-ChildItem -LiteralPath $cursorSrc -Force | ForEach-Object {
    $target = Join-Path $cursorDest $_.Name
    if ($_.PSIsContainer) {
      Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    } else {
      Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
  }
  Write-Host "Copied .cursor to project." -ForegroundColor Green
}

# Copy precursor to project-doctor
$precursorSrc = Join-Path $CuratedRoot "packages\precursor"
$projectDoctorDest = Join-Path $dest "project-doctor"
if (Test-Path $precursorSrc) {
  Copy-Item -LiteralPath $precursorSrc -Destination $projectDoctorDest -Recurse -Force
  Write-Host "Copied Precursor to project-doctor." -ForegroundColor Green
}

# git init
if (Get-Command git -ErrorAction SilentlyContinue) {
  Push-Location $dest
  try {
    git init 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Initialized git repository." -ForegroundColor Green
    }
  } finally {
    Pop-Location
  }
}

# Optional -RunDoctor: from $dest\project-doctor: bun install then bun run src/cli.ts setup
if ($RunDoctor) {
  Write-Host "Running doctor in project-doctor..." -ForegroundColor Yellow
  $doctorDir = Join-Path $dest "project-doctor"
  if (Test-Path (Join-Path $doctorDir "package.json")) {
    Push-Location -LiteralPath $doctorDir
    try {
      if (Test-Path (Join-Path $doctorDir "bun.lock")) {
        bun install --frozen-lockfile
      } else {
        bun install
      }
      if ($LASTEXITCODE -eq 0) {
        bun run src/cli.ts setup
      }
    } finally {
      Pop-Location
    }
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Doctor completed with exit code $LASTEXITCODE." -ForegroundColor Yellow
    } else {
      Write-Host "Doctor completed." -ForegroundColor Green
    }
  } else {
    Write-Host "project-doctor/package.json not found, skipping doctor." -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Project created: $dest" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  cd `"$dest`"" -ForegroundColor White
Write-Host "  Open in Cursor: cursor `"$dest`"" -ForegroundColor White
