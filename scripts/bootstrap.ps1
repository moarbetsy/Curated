<#
.SYNOPSIS
  One-time bootstrap for Curated on a fresh Windows machine.
  Run from raw URL; installs tools via winget, downloads Curated, restarts once for PATH, then runs gen-rules, doctor, scan.
  Optional: create a new project after bootstrap.

.DESCRIPTION
  Phase Install: winget install (PowerShell 7, Python 3.11 + latest, Bun, uv, Git, Node LTS, Cursor, just),
  download repo zip, expand to path without spaces (default $env:USERPROFILE\Curated), then re-launch with Phase Configure.
  Phase Configure: gen-rules, doctor, scan, MCP setup; optionally run curated.ps1 new -Name <NewProjectName> -RunDoctor.
  All paths that might contain spaces are passed quoted. Uses process-level -ExecutionPolicy Bypass only.

.PARAMETER RepoUrl
  Repository URL, e.g. https://github.com/<OWNER>/<REPO>

.PARAMETER Ref
  Branch or tag for zip download (default: main).

.PARAMETER NewProjectName
  If set, after bootstrap run: curated.ps1 new -Name <name> -RunDoctor.

.PARAMETER CuratedPath
  Install directory (default: $env:USERPROFILE\Curated). Use path without spaces.

.PARAMETER Phase
  Internal: Install (winget + download + restart) or Configure (gen-rules, doctor, scan, MCP, optional new project).
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoUrl,

  [string]$Ref = "main",

  [string]$NewProjectName,

  [string]$CuratedPath,

  [ValidateSet("Install", "Configure")]
  [string]$Phase = "Install"
)

$ErrorActionPreference = "Stop"

# Default install path: path without spaces (e.g. $env:USERPROFILE\Curated)
if (-not $CuratedPath) {
  $CuratedPath = Join-Path $env:USERPROFILE "Curated"
}

# --- Winget check (required at start) ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget is not available. Install App Installer / winget from Microsoft Store, then run this script again." -ForegroundColor Red
  exit 1
}

function Invoke-WingetInstall {
  param([string]$Id, [string]$Name = $Id)
  $existing = winget list --id $Id --exact 2>$null
  if ($LASTEXITCODE -eq 0 -and $existing -match $Id) {
    Write-Host "  $Name already installed, skipping." -ForegroundColor Gray
    return
  }
  Write-Host "  Installing $Name..." -ForegroundColor Cyan
  winget install --id $Id --exact --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  WARNING: winget install $Id returned $LASTEXITCODE" -ForegroundColor Yellow
  }
}

if ($Phase -eq "Install") {
  Write-Host "Phase: Install (winget + download)" -ForegroundColor Cyan
  Write-Host ""

  # Winget installs (process-level bypass for any subscripts is implicit when we spawn pwsh -ExecutionPolicy Bypass)
  Write-Host "Installing tools via winget..." -ForegroundColor Yellow
  Invoke-WingetInstall -Id "Microsoft.PowerShell" -Name "PowerShell 7"
  Invoke-WingetInstall -Id "Python.Python.3.11" -Name "Python 3.11"
  Invoke-WingetInstall -Id "Python.Python.3" -Name "Python (latest)"
  Invoke-WingetInstall -Id "Oven-sh.Bun" -Name "Bun"
  Invoke-WingetInstall -Id "astral-sh.uv" -Name "uv"
  Invoke-WingetInstall -Id "Git.Git" -Name "Git"
  Invoke-WingetInstall -Id "OpenJS.NodeJS.LTS" -Name "Node LTS"
  Invoke-WingetInstall -Id "Anysphere.Cursor" -Name "Cursor"
  Invoke-WingetInstall -Id "Casey.Just" -Name "just"
  Write-Host ""

  # Download zip (e.g. https://github.com/owner/repo/archive/refs/heads/main.zip)
  $base = $RepoUrl.TrimEnd('/')
  $zipUrl = "$base/archive/refs/heads/$Ref.zip"
  $zipPath = Join-Path $env:TEMP "Curated.zip"
  $extractDir = Join-Path $env:TEMP "Curated-extract"

  Write-Host "Downloading Curated from $zipUrl ..." -ForegroundColor Yellow
  $downloadOk = $false
  foreach ($attempt in 1..2) {
    try {
      Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
      $downloadOk = $true
      break
    } catch {
      Write-Host "  Download attempt $attempt failed: $($_.Exception.Message)" -ForegroundColor Red
      if ($attempt -eq 2) {
        Write-Host "Download failed after 2 attempts. Exiting." -ForegroundColor Red
        exit 1
      }
    }
  }

  if (-not (Test-Path $zipPath)) {
    Write-Host "Download failed: $zipPath not found." -ForegroundColor Red
    exit 1
  }

  if (Test-Path $extractDir) {
    Remove-Item -LiteralPath $extractDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
  Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

  $innerFolders = Get-ChildItem -LiteralPath $extractDir -Directory
  if ($innerFolders.Count -ne 1) {
    Write-Host "Unexpected zip layout: expected one folder under extract dir." -ForegroundColor Red
    exit 1
  }
  $innerPath = $innerFolders[0].FullName

  $curatedParent = Split-Path -Parent $CuratedPath
  if (-not (Test-Path $curatedParent)) {
    New-Item -ItemType Directory -Path $curatedParent -Force | Out-Null
  }
  if (Test-Path $CuratedPath) {
    Remove-Item -LiteralPath $CuratedPath -Recurse -Force
  }
  Move-Item -LiteralPath $innerPath -Destination $CuratedPath -Force
  Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue

  Write-Host "Curated installed to: $CuratedPath" -ForegroundColor Green
  Write-Host "Restarting script with Phase=Configure so PATH (pwsh, bun, etc.) is visible..." -ForegroundColor Cyan

  $bootstrapScript = Join-Path $CuratedPath "scripts\bootstrap.ps1"
  $restartArgs = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $bootstrapScript,
    "-RepoUrl", $RepoUrl,
    "-Ref", $Ref,
    "-CuratedPath", $CuratedPath,
    "-Phase", "Configure"
  )
  if ($NewProjectName) {
    $restartArgs += "-NewProjectName", $NewProjectName
  }
  & pwsh @restartArgs
  exit $LASTEXITCODE
}

# --- Phase Configure ---
Write-Host "Phase: Configure (gen-rules, doctor, scan, MCP, optional new project)" -ForegroundColor Cyan
Write-Host ""

$curatedPs1 = Join-Path $CuratedPath "curated.ps1"
if (-not (Test-Path $curatedPs1)) {
  Write-Host "curated.ps1 not found at: $curatedPs1" -ForegroundColor Red
  exit 1
}

# Optional: verify pwsh, bun in PATH after restart
$pwshOk = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $pwshOk) {
  Write-Host "pwsh not in PATH. Open a new terminal (or re-run bootstrap with -Phase Configure) and run Configure phase manually." -ForegroundColor Yellow
}

Write-Host "Running gen-rules, doctor, scan from Curated..." -ForegroundColor Yellow
& pwsh -NoProfile -ExecutionPolicy Bypass -File $curatedPs1 gen-rules
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& pwsh -NoProfile -ExecutionPolicy Bypass -File $curatedPs1 doctor
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& pwsh -NoProfile -ExecutionPolicy Bypass -File $curatedPs1 scan
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# MCP setup under $CuratedPath
$cursorDir = Join-Path $CuratedPath ".cursor"
$mcpDir = Join-Path $cursorDir "mcp"
if (-not (Test-Path $cursorDir)) {
  New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null
}
if (-not (Test-Path $mcpDir)) {
  New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null
}
$browserJson = Join-Path $mcpDir "browser.json"
if (-not (Test-Path $browserJson)) {
  @{
    mcpServers = @{
      "cursor-ide-browser" = @{
        command = "cursor-ide-browser"
        args    = @()
        env     = @{}
      }
    }
  } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $browserJson -Encoding UTF8
  Write-Host "MCP browser server configured at .cursor/mcp/browser.json" -ForegroundColor Green
}
$precursorMcpSrc = Join-Path $CuratedPath "packages\precursor\.cursor\mcp.json"
$mcpJsonPath = Join-Path $CuratedPath ".cursor\mcp.json"
if (Test-Path $precursorMcpSrc) {
  $precursorContent = Get-Content -LiteralPath $precursorMcpSrc -Raw | ConvertFrom-Json
  $precursorServer = $precursorContent.mcpServers.precursor
  if ($precursorServer) {
    $precursorServer.args = @("packages/precursor/.precursor/mcp/server.ts")
    $merged = @{
      mcpServers = @{
        "cursor-ide-browser" = @{
          command = "cursor-ide-browser"
          args    = @()
          env     = @{}
        }
        "precursor" = @{
          command = $precursorServer.command
          args    = $precursorServer.args
          env     = if ($precursorServer.env) { $precursorServer.env } else { @{} }
        }
      }
    }
    $merged | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $mcpJsonPath -Encoding UTF8
    Write-Host "MCP .cursor/mcp.json updated (cursor-ide-browser + precursor)." -ForegroundColor Green
  }
}

if ($NewProjectName) {
  Write-Host ""
  Write-Host "Creating new project: $NewProjectName (with -RunDoctor)..." -ForegroundColor Yellow
  & pwsh -NoProfile -ExecutionPolicy Bypass -File $curatedPs1 new -Name $NewProjectName -RunDoctor
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Single test command:" -ForegroundColor Cyan
Write-Host ('  pwsh -NoProfile -ExecutionPolicy Bypass -File "' + $curatedPs1 + '" test') -ForegroundColor White
Write-Host ""
Write-Host "Or run self-test:" -ForegroundColor Cyan
$selfTest = Join-Path $CuratedPath "scripts\self-test.ps1"
Write-Host ('  pwsh -NoProfile -ExecutionPolicy Bypass -File "' + $selfTest + '"') -ForegroundColor White
