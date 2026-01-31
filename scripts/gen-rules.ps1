<#[
Generate Cursor rules from rules-src (single source of truth).

- Edit rules in:     rules-src/
- Generated outputs: .cursor/rules/, packages/*/.cursor/rules/

Usage:
  pwsh ./scripts/gen-rules.ps1
  pwsh ./scripts/gen-rules.ps1 -Check
#>

param(
  [switch]$Check
)

$ErrorActionPreference = 'Stop'

function RepoRoot() {
  return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

function NormalizeEol([string]$Content) {
  # Normalize CRLF/CR to LF for cross-platform stable comparisons.
  return ($Content -replace "`r`n", "`n") -replace "`r", "`n"
}

function ReadUtf8([string]$Path) {
  return NormalizeEol (Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
}

function WriteUtf8([string]$Path, [string]$Content) {
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $normalized = NormalizeEol $Content
  # Use .NET to avoid PowerShell newline translation (CRLF injection) on Windows.
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

function EnsureNotJsonWrapped([string]$Path, [string]$Content) {
  $trim = $Content.TrimStart()
  if ($trim.StartsWith('{')) {
    throw "Refusing to write JSON-wrapped rule: $Path"
  }
}

$root = RepoRoot
$srcRules = Join-Path $root 'rules-src\rules'
$srcIncidents = Join-Path $root 'rules-src\INCIDENTS.md'

if (-not (Test-Path -LiteralPath $srcRules)) {
  throw "Missing rules-src. Expected: $srcRules"
}
if (-not (Test-Path -LiteralPath $srcIncidents)) {
  throw "Missing INCIDENTS source. Expected: $srcIncidents"
}

# --- Targets ---
$rootMdcRules = @(
  'agent-protocol',
  'commands',
  'diagnostics',
  'issue-reporting-and-apply-report',
  'knowledge-base',
  'verification',
  'windows-systems-and-toolchain'
)

$setupCursorRuleDirs = @(
  'diagnostics',
  'issue-reporting-and-apply-report',
  'python-3-14',
  'windows-systems-and-toolchain'
)

$precursorMdcRules = @(
  'diagnostics',
  'issue-reporting-and-apply-report',
  'python-3-14',
  'python',
  'web',
  'windows-systems-and-toolchain'
)

$precursorRuleDirs = @(
  'diagnostics',
  'issue-reporting-and-apply-report',
  'python-3-14',
  'windows-systems-and-toolchain'
)

# --- Planning output paths ---
$writes = @()

foreach ($id in $rootMdcRules) {
  $src = Join-Path $srcRules ("$id.md")
  $dst = Join-Path $root (".cursor\rules\$id.mdc")
  $writes += [pscustomobject]@{ Id=$id; Src=$src; Dst=$dst }
}

# INCIDENTS.md (plain)
$writes += [pscustomobject]@{ Id='INCIDENTS'; Src=$srcIncidents; Dst=(Join-Path $root '.cursor\rules\INCIDENTS.md') }

foreach ($id in $setupCursorRuleDirs) {
  $src = Join-Path $srcRules ("$id.md")
  $dst = Join-Path $root ("packages\setup-cursor\.cursor\rules\$id\RULE.md")
  $writes += [pscustomobject]@{ Id="setup-cursor:$id"; Src=$src; Dst=$dst }
}
$writes += [pscustomobject]@{ Id='setup-cursor:INCIDENTS'; Src=$srcIncidents; Dst=(Join-Path $root 'packages\setup-cursor\.cursor\rules\INCIDENTS.md') }

foreach ($id in $precursorMdcRules) {
  $src = Join-Path $srcRules ("$id.md")
  $dst = Join-Path $root ("packages\precursor\.cursor\rules\$id.mdc")
  $writes += [pscustomobject]@{ Id="precursor:$id"; Src=$src; Dst=$dst }
}
foreach ($id in $precursorRuleDirs) {
  $src = Join-Path $srcRules ("$id.md")
  $dst = Join-Path $root ("packages\precursor\.cursor\rules\$id\RULE.md")
  $writes += [pscustomobject]@{ Id="precursor-dir:$id"; Src=$src; Dst=$dst }
}

# --- Execute ---
$errors = @()
foreach ($w in $writes) {
  if (-not (Test-Path -LiteralPath $w.Src)) {
    $errors += "Missing source for $($w.Id): $($w.Src)"
    continue
  }

  $content = ReadUtf8 $w.Src
  EnsureNotJsonWrapped -Path $w.Dst -Content $content

  if ($Check) {
    if (-not (Test-Path -LiteralPath $w.Dst)) {
      $errors += "Missing generated output for $($w.Id): $($w.Dst)"
      continue
    }
    $existing = ReadUtf8 $w.Dst
    if ($existing -ne $content) {
      $errors += "Drift detected for $($w.Id): $($w.Dst)"
    }
  } else {
    WriteUtf8 -Path $w.Dst -Content $content
  }
}

if ($errors.Count -gt 0) {
  $msg = ($errors -join "`n")
  if ($Check) {
    throw "Rule generation check failed:`n$msg"
  }
  throw "Rule generation failed:`n$msg"
}

if ($Check) {
  Write-Host "Rules are in sync with rules-src." -ForegroundColor Green
} else {
  Write-Host "Rules generated from rules-src." -ForegroundColor Green
}
