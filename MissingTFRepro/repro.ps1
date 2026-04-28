# Repro for https://github.com/nuget/home/issues/12470
# "Attribute TargetFramework errors to the offending project"
#
# Setup: ProjectA -> ProjectB, where ProjectB has an empty TargetFramework.
# The bug: when restoring ProjectA, the error is attributed to ProjectA, not ProjectB.

$ErrorActionPreference = "Continue"
$base = $PSScriptRoot

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Repro for NuGet/Home#12470" -ForegroundColor Cyan
Write-Host "ProjectA (net8.0) -> ProjectB (empty TFM)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Test 1: Restore ProjectB directly ---
Write-Host "`n--- Test 1: dotnet restore ProjectB directly ---" -ForegroundColor Yellow
& dotnet restore "$base\ProjectB\ProjectB.csproj" --verbosity minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

# --- Test 2: Restore ProjectA directly (references ProjectB) ---
Write-Host "--- Test 2: dotnet restore ProjectA directly (references ProjectB) ---" -ForegroundColor Yellow
& dotnet restore "$base\ProjectA\ProjectA.csproj" --verbosity minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

# --- Test 3: Restore via solution ---
Write-Host "--- Test 3: dotnet restore via solution ---" -ForegroundColor Yellow
& dotnet restore "$base\MissingTFRepro.slnx" --verbosity minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

# --- Test 4: msbuild -t:restore ProjectB directly ---
Write-Host "--- Test 4: msbuild -t:restore ProjectB directly ---" -ForegroundColor Yellow
& msbuild -t:restore "$base\ProjectB\ProjectB.csproj" -v:minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

# --- Test 5: msbuild -t:restore ProjectA directly ---
Write-Host "--- Test 5: msbuild -t:restore ProjectA directly ---" -ForegroundColor Yellow
& msbuild -t:restore "$base\ProjectA\ProjectA.csproj" -v:minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

# --- Test 6: msbuild -t:restore via solution ---
Write-Host "--- Test 6: msbuild -t:restore via solution ---" -ForegroundColor Yellow
& msbuild -t:restore "$base\MissingTFRepro.slnx" -v:minimal 2>&1
Write-Host "Exit code: $LASTEXITCODE`n"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Expected: errors should point to ProjectB.csproj (the offending project)" -ForegroundColor Cyan
Write-Host "Bug: errors are attributed to ProjectA.csproj when restoring A" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
