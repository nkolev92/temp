# Repro Summary: NuGet/Home#12470

**Issue:** [Attribute TargetFramework errors to the offending project](https://github.com/nuget/home/issues/12470)

## Setup

- **ProjectA** (`net8.0`) → references **ProjectB** (empty `TargetFramework`)
- A solution (`MissingTFRepro.slnx`) contains both projects
- Repro location: `E:\Code\Temp\temp\MissingTFRepro\`

## Results

### Without Static Graph (default)

| # | Command | Error | Attributed To | Correct? |
|---|---------|-------|---------------|----------|
| 1 | `dotnet restore ProjectB` | `NETSDK1013: The TargetFramework value '' was not recognized.` | **ProjectB.csproj** | ✅ Yes |
| 2 | `dotnet restore ProjectA` | `Invalid framework identifier ''.` | **ProjectA.csproj** | ❌ No |
| 3 | `dotnet restore solution` | `Invalid framework identifier ''.` | **MissingTFRepro.slnx** | ❌ No |
| 4 | `msbuild -t:restore ProjectB` | `NETSDK1013: The TargetFramework value '' was not recognized.` | **ProjectB.csproj** | ✅ Yes |
| 5 | `msbuild -t:restore ProjectA` | `Invalid framework identifier ''.` | **ProjectA.csproj** | ❌ No |
| 6 | `msbuild -t:restore solution` | `Invalid framework identifier ''.` | **MissingTFRepro.slnx** | ❌ No |

### With Static Graph (`/p:RestoreUseStaticGraphEvaluation=true`)

| # | Command | Error | Attributed To | Correct? |
|---|---------|-------|---------------|----------|
| SG1 | `dotnet restore ProjectB` | `NETSDK1013: The TargetFramework value '' was not recognized.` | **ProjectB.csproj** | ✅ Yes |
| SG2 | `dotnet restore ProjectA` | `error` (from `NuGet.RestoreEx.targets`) | No project attribution | ❌ No |
| SG3 | `dotnet restore solution` | `error` (from `NuGet.RestoreEx.targets`) | No project attribution | ❌ No |
| SG4 | `msbuild -t:restore ProjectB` | `NETSDK1013: The TargetFramework value '' was not recognized.` | **ProjectB.csproj** | ✅ Yes |
| SG5 | `msbuild -t:restore ProjectA` | `Invalid framework identifier ''.` + full stack trace | **ProjectA.csproj** | ❌ No |
| SG6 | `msbuild -t:restore solution` | `Invalid framework identifier ''.` + full stack trace | **MissingTFRepro.slnx** | ❌ No |

## Key Findings

1. **Direct restore of the offending project works correctly.** Restoring ProjectB directly produces a clear `NETSDK1013` error correctly attributed to `ProjectB.csproj` — with and without static graph.

2. **Indirect restore misattributes the error.** When ProjectB is restored as a dependency of ProjectA (or via the solution), the error is attributed to the caller (`ProjectA.csproj` or `MissingTFRepro.slnx`) — never mentioning ProjectB. This is true with and without static graph.

3. **The error message degrades.** Direct restore gives the descriptive `NETSDK1013` with guidance. Indirect restore gives a generic `Invalid framework identifier ''` with no error code.

4. **Static graph makes things worse.** With static graph enabled:
   - `dotnet restore` (SG2, SG3) produces a bare `error` from `NuGet.RestoreEx.targets` with **no project attribution at all** and no useful message.
   - `msbuild -t:restore` (SG5, SG6) produces the same misattributed error as without static graph, but **additionally leaks a full .NET stack trace** (`NuGetFramework.GetShortFolderName` → `PackageSpecFactory` → `MSBuildStaticGraphRestore`).

5. **Both `dotnet restore` and `msbuild -t:restore` exhibit the same core misattribution behavior**, regardless of static graph.

## Tested With

- MSBuild 18.6.1+e5ebe1565
- .NET SDK 10.0.300-preview.0.26177.108
