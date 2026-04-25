# Repro for https://github.com/dotnet/msbuild/issues/10801
# MSBuildTreatWarningsAsErrors does not integrate with WarningsNotAsErrors well - project vs solution

$ErrorActionPreference = "Continue"
$repoRoot = $PSScriptRoot

Write-Host "`n=== Running from repo root ===" -ForegroundColor Cyan
Push-Location $repoRoot

Write-Host "`n--- Restore specifying project file (expect: warning NU1603, actual: ERROR NU1603) ---" -ForegroundColor Yellow
& msbuild -t:restore src/Warnings.csproj -v:minimal
Write-Host "Exit code: $LASTEXITCODE"

Write-Host "`n--- Restore specifying solution folder (expect: warning NU1603) ---" -ForegroundColor Yellow
& msbuild -t:restore src/ -v:minimal
Write-Host "Exit code: $LASTEXITCODE"

Pop-Location

Write-Host "`n=== Running from project folder ===" -ForegroundColor Cyan
Push-Location "$repoRoot\src"

Write-Host "`n--- Restore specifying project file (expect: warning NU1603, actual: ERROR NU1603) ---" -ForegroundColor Yellow
& msbuild -t:restore Warnings.csproj -v:minimal
Write-Host "Exit code: $LASTEXITCODE"

Write-Host "`n--- Restore without specifying file (uses sln, expect: warning NU1603) ---" -ForegroundColor Yellow
& msbuild -t:restore -v:minimal
Write-Host "Exit code: $LASTEXITCODE"

Pop-Location

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "When restoring the project directly, NU1603 should be a WARNING (WarningsNotAsErrors)."
Write-Host "When restoring via solution, NU1603 IS a warning."
Write-Host "BUG: Direct project restore treats NU1603 as an ERROR despite WarningsNotAsErrors."
