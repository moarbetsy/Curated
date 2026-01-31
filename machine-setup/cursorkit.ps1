# Wrapper: forwards to packages/setup-cursor/cursorkit.ps1
$target = Join-Path $PSScriptRoot "..\packages\setup-cursor\cursorkit.ps1"
if (-not (Test-Path $target)) {
    Write-Error "Target script not found: $target"
    exit 1
}
& $target @args
