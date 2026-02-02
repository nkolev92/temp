Write-Host "Starting clean and restore process..."
git clean -xdf
dotnet restore
Write-Host "Starting clean and restore process with --source option..."
git clean -xdf
dotnet restore --source "http://api.nuget.org/v3/index.json"