param(
  [string]$ReportPath,
  [switch]$WriteChecklist,
  [string]$ChecklistPath
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

if (-not $ReportPath) {
  $ReportPath = Join-Path $PSScriptRoot "..\docs\REPORT.md"
}
if (-not (Test-Path -LiteralPath $ReportPath)) {
  Write-Host "Missing report file: $ReportPath" -ForegroundColor Red
  exit 1
}

$content = Get-Content -LiteralPath $ReportPath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($content)) {
  Write-Host "Report is empty: $ReportPath" -ForegroundColor Yellow
  exit 0
}

$lines = $content -split "`n"
$entries = @()
$current = $null

foreach ($line in $lines) {
  if ($line -match '^\s*###\s+(?<title>.+)$') {
    if ($current) { $entries += $current }
    $current = [pscustomobject]@{
      Title  = $Matches.title.Trim()
      Status = $null
      Lines  = @()
    }
    continue
  }

  if ($current) {
    $current.Lines += $line
    if ($line -match '^\s*-\s*\*\*Status\*\*:\s*(?<status>.+?)\s*$') {
      $current.Status = $Matches.status.Trim()
    }
  }
}
if ($current) { $entries += $current }

$targets = $entries | Where-Object {
  $_.Status -and $_.Status -match '^(?i)(unresolved|mitigated)$'
}

if (-not $targets -or $targets.Count -eq 0) {
  Write-Host "No unresolved/mitigated entries found in $ReportPath." -ForegroundColor Green
  exit 0
}

Write-Host "Unresolved/mitigated entries:" -ForegroundColor Yellow
foreach ($entry in $targets) {
  Write-Host ("- {0} (Status: {1})" -f $entry.Title, $entry.Status)
}

Write-Host "" 
Write-Host "Checklist (per entry):" -ForegroundColor Cyan
Write-Host "1) Reproduce safely with minimal commands."
Write-Host "2) Apply a permanent fix (config/script/code), not a one-off."
Write-Host "3) Verify by re-running relevant commands."
Write-Host "4) Append a follow-up entry in docs/REPORT.md marking it resolved."

if ($WriteChecklist) {
  if (-not $ChecklistPath) {
    $ChecklistPath = Join-Path $PSScriptRoot "..\docs\REPORT_APPLY.md"
  }

  $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
  $linesOut = @(
    "# Apply Report Checklist",
    "",
    "Generated: $stamp (local)",
    "",
    "## Unresolved/mitigated entries"
  )

  foreach ($entry in $targets) {
    $linesOut += "- [ ] $($entry.Title) (Status: $($entry.Status))"
  }

  $linesOut += ""
  $linesOut += "## Steps"
  $linesOut += "1. Reproduce safely with minimal commands."
  $linesOut += "2. Apply a permanent fix (config/script/code), not a one-off."
  $linesOut += "3. Verify by re-running relevant commands."
  $linesOut += "4. Append a follow-up entry in docs/REPORT.md marking it resolved."

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($ChecklistPath, ($linesOut -join "`n"), $utf8NoBom)
  Write-Host "Wrote checklist to $ChecklistPath" -ForegroundColor Green
}