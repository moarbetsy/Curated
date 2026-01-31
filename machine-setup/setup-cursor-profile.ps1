# Wrapper: forwards to packages/setup-cursor/setup-cursor-profile.ps1
$target = Join-Path $PSScriptRoot "..\packages\setup-cursor\setup-cursor-profile.ps1"
if (-not (Test-Path $target)) {
    Write-Error "Target script not found: $target"
    exit 1
}
& $target @args
