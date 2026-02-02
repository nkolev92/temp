git clean -xdf
dotnet restore
git clean -xdf
dotnet restore --source "http://api.nuget.org/v3/index.json"