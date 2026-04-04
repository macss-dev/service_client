# Cross-language parity test runner
# Validates that Dart, TypeScript, and Python implementations produce
# identical results for shared test fixtures in ../fixtures/.
#
# Usage: pwsh code/tests/integration_test/parity_test.ps1
#
# Prerequisites:
#   - Dart SDK, Node.js, Python 3.11+ installed
#   - Each SDK built and dependencies resolved

param(
    [switch]$DartOnly,
    [switch]$TsOnly,
    [switch]$PyOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path "$PSScriptRoot/../../.."
$failed = @()

function Write-Section($label) {
    Write-Host "`n=== $label ===" -ForegroundColor Cyan
}

# --- Dart ---
if (-not $TsOnly -and -not $PyOnly) {
    Write-Section "Dart parity tests"
    Push-Location "$repoRoot/code/dart"
    try {
        dart test test/parity_test.dart --reporter expanded
        if ($LASTEXITCODE -ne 0) { $failed += "Dart" }
    } catch {
        Write-Host "Dart: FAILED — $_" -ForegroundColor Red
        $failed += "Dart"
    } finally {
        Pop-Location
    }
}

# --- TypeScript ---
if (-not $DartOnly -and -not $PyOnly) {
    Write-Section "TypeScript parity tests"
    Push-Location "$repoRoot/code/ts"
    try {
        npx vitest run test/parity.test.ts
        if ($LASTEXITCODE -ne 0) { $failed += "TypeScript" }
    } catch {
        Write-Host "TypeScript: FAILED — $_" -ForegroundColor Red
        $failed += "TypeScript"
    } finally {
        Pop-Location
    }
}

# --- Python ---
if (-not $DartOnly -and -not $TsOnly) {
    Write-Section "Python parity tests"
    Push-Location "$repoRoot/code/py"
    try {
        $venvPython = if (Test-Path ".venv/Scripts/python.exe") { ".venv/Scripts/python.exe" } else { "python" }
        & $venvPython -m pytest tests/test_parity.py -v
        if ($LASTEXITCODE -ne 0) { $failed += "Python" }
    } catch {
        Write-Host "Python: FAILED — $_" -ForegroundColor Red
        $failed += "Python"
    } finally {
        Pop-Location
    }
}

# --- Summary ---
Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "ALL PARITY TESTS PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "PARITY FAILURES: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
