# How To: Initialize a New .NET Project

## Prerequisites

- `init.ps1` in project root (copy from templates)

## Usage

```powershell
.\init.ps1 -Name <ProjectPrefix> [-Console] [-Core] [-Ui]
```

## Flags

| Flag | Creates |
|------|---------|
| `-Console` | Console application `<Name>.Console`) |
| `-Core` | Class library for shared code `<Name>.Core`) |
| `-Ui` | WPF application `<Name>.Ui`) |

## Examples

### Console app with shared library

```powershell
.\init.ps1 -Name CarpFlow -Console -Core
```

### Full app with UI, Console, and Core

```powershell
.\init.ps1 -Name MyApp -Console -Core -Ui
```

## What It Does

1. Creates solution in `src/`
2. Creates requested projects in `src/<Name>.<Type>/`
3. Adds projects to solution
4. Adds Core reference to Console and Ui projects (if Core is included)

## After Running

1. Add publish settings to `.csproj` files (see guide section 10.2)
2. Create `BuildInfo.cs` in app projects
3. Build with `.\build.ps1 -Project <name>`
