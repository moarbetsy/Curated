# Wrapper module: forwards to packages/setup-cursor/setup-cursor.psm1
$real = Join-Path $PSScriptRoot "..\packages\setup-cursor\setup-cursor.psm1"
if (-not (Test-Path $real)) {
    throw "Real module not found: $real"
}
. $real
