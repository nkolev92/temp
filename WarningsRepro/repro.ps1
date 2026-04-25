#!/usr/bin/env pwsh
# Repro script for https://github.com/dotnet/msbuild/issues/10871#issuecomment-4253934864
#
# Tests whether WarningsNotAsErrors properly downgrades warnings when
# both TreatWarningsAsErrors and MSBuildTreatWarningsAsErrors are set.
#
# The csproj references System.Text.Json 8.0.0 which has known vulnerabilities,
# triggering NU1903 audit warnings. WarningsNotAsErrors=NU1903 should keep it as a warning.

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

Write-Host "=== dotnet --version ===" -ForegroundColor Cyan
dotnet --version

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test 1: TreatWarningsAsErrors + MSBuildTreatWarningsAsErrors + WarningsNotAsErrors=NU1903" -ForegroundColor Yellow
Write-Host "Expected: restore should SUCCEED (NU1903 downgraded to warning)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

dotnet restore --no-cache -v n 2>&1
$test1Exit = $LASTEXITCODE
Write-Host ""
if ($test1Exit -eq 0) {
    Write-Host "✅ Test 1 PASSED: restore succeeded (exit code $test1Exit)" -ForegroundColor Green
} else {
    Write-Host "❌ Test 1 FAILED: restore failed (exit code $test1Exit)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test 2: Override - only TreatWarningsAsErrors (no MSBuildTreatWarningsAsErrors) + WarningsNotAsErrors=NU1903" -ForegroundColor Yellow
Write-Host "Expected: restore should SUCCEED" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

dotnet restore --no-cache -v n /p:MSBuildTreatWarningsAsErrors=false 2>&1
$test2Exit = $LASTEXITCODE
Write-Host ""
if ($test2Exit -eq 0) {
    Write-Host "✅ Test 2 PASSED: restore succeeded (exit code $test2Exit)" -ForegroundColor Green
} else {
    Write-Host "❌ Test 2 FAILED: restore failed (exit code $test2Exit)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test 3: Only MSBuildTreatWarningsAsErrors (no TreatWarningsAsErrors) + WarningsNotAsErrors=NU1903" -ForegroundColor Yellow
Write-Host "Expected: If MSBuild respects WarningsNotAsErrors, should SUCCEED" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

dotnet restore --no-cache -v n /p:TreatWarningsAsErrors=false 2>&1
$test3Exit = $LASTEXITCODE
Write-Host ""
if ($test3Exit -eq 0) {
    Write-Host "✅ Test 3 PASSED: restore succeeded (exit code $test3Exit)" -ForegroundColor Green
} else {
    Write-Host "❌ Test 3 FAILED: restore failed (exit code $test3Exit)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test 4: MSBuildTreatWarningsAsErrors + MSBuildWarningsNotAsErrors=NU1903 (MSBuild-prefixed downgrade)" -ForegroundColor Yellow
Write-Host "Expected: restore should SUCCEED" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

dotnet restore --no-cache -v n /p:TreatWarningsAsErrors=false /p:MSBuildWarningsNotAsErrors=NU1903 /p:WarningsNotAsErrors= 2>&1
$test4Exit = $LASTEXITCODE
Write-Host ""
if ($test4Exit -eq 0) {
    Write-Host "✅ Test 4 PASSED: restore succeeded (exit code $test4Exit)" -ForegroundColor Green
} else {
    Write-Host "❌ Test 4 FAILED: restore failed (exit code $test4Exit)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test 5: Both TreatWarningsAsErrors + MSBuildTreatWarningsAsErrors, NO downgrade" -ForegroundColor Yellow
Write-Host "Expected: restore should FAIL (NU1903 promoted to error)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

dotnet restore --no-cache -v n /p:WarningsNotAsErrors= 2>&1
$test5Exit = $LASTEXITCODE
Write-Host ""
if ($test5Exit -ne 0) {
    Write-Host "✅ Test 5 PASSED: restore failed as expected (exit code $test5Exit)" -ForegroundColor Green
} else {
    Write-Host "❌ Test 5 FAILED: restore unexpectedly succeeded (exit code $test5Exit)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 1 (Both + WarningsNotAsErrors):             Exit=$test1Exit $(if($test1Exit -eq 0){'PASS'}else{'FAIL'})"
Write-Host "Test 2 (TreatWarningsAsErrors only + downgrade): Exit=$test2Exit $(if($test2Exit -eq 0){'PASS'}else{'FAIL'})"
Write-Host "Test 3 (MSBuildTreatWarningsAsErrors only + WarningsNotAsErrors): Exit=$test3Exit $(if($test3Exit -eq 0){'PASS'}else{'FAIL'})"
Write-Host "Test 4 (MSBuildTreatWarningsAsErrors + MSBuildWarningsNotAsErrors): Exit=$test4Exit $(if($test4Exit -eq 0){'PASS'}else{'FAIL'})"
Write-Host "Test 5 (Both, no downgrade - expect fail):       Exit=$test5Exit $(if($test5Exit -ne 0){'PASS'}else{'FAIL'})"

Pop-Location
