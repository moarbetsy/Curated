<#
.SYNOPSIS
  Single command to verify the whole Curated stack after bootstrap (no need to cd into Curated).

.DESCRIPTION
  Resolves Curated root via $env:CURATED_HOME or $env:USERPROFILE\Curated, then runs curated.ps1 test.
  Use quoted path when invoking curated.ps1. Optional -CuratedPath for CI or custom installs.

.PARAMETER CuratedPath
  Override Curated root (default: $env:CURATED_HOME or $env:USERPROFILE\Curated).
#>
param(
  [string]$CuratedPath
)

$ErrorActionPreference = "Stop"

if ($CuratedPath) {
  $CuratedRoot = $CuratedPath
} elseif ($env:CURATED_HOME) {
  $CuratedRoot = $env:CURATED_HOME
} else {
  $CuratedRoot = Join-Path $env:USERPROFILE "Curated"
}

$curatedPs1 = Join-Path $CuratedRoot "curated.ps1"
if (-not (Test-Path $curatedPs1)) {
  Write-Host "curated.ps1 not found at: $curatedPs1" -ForegroundColor Red
  Write-Host "Set CURATED_HOME or run from Curated root, or pass -CuratedPath." -ForegroundColor Yellow
  exit 1
}

& pwsh -NoProfile -ExecutionPolicy Bypass -File $curatedPs1 test
exit $LASTEXITCODE
