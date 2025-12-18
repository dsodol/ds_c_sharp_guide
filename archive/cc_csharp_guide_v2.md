# C# Project Guide v2

## 1. Purpose

Defines defaults for creating C# applications. Claude follows this guide unless the user specifies otherwise.

"I" and "me" in this guide refers to the human user.

Read next: `cc_ui_guide.md` (when building UI)

---

## 2. Context

Projects are for personal use.

My tastes are peculiar and can be described as old school. Examples: no dark themes by default. When Claude must choose between new and shiny vs older but stable — prefer older, nicer, more usable, more stable.

Installers, when present, are for convenience only.

---

## 3. Platform

| Setting | Default |
|---------|---------|
| .NET | 10 |
| Configuration | Debug only — never Release |
| Runtime | win-x64 |
| UI Framework | WPF |

---

## 4. Typical Project Composition

A typical project contains both UI and console apps. They typically share code.

---

## 5. Naming

- `snake_case` for project/folder names
- `PascalCase.With.Dots` for C# namespaces, project names, classes, methods

Example: folder `my_cool_app`, C# project `MyCoolApp.Console`

---

## 6. Architecture

- **Pattern:** Code-Behind + Service Layer
- Do NOT use MVVM unless explicitly requested

---

## 7. Project Bootstrap

When I create a new project, I copy template files from `..\ds_c_sharp_guide\templates` into the project folder. When Claude first reads instructions in a greenfield project, these files are expected to already be present.

To initialize .NET projects, see `howtos/init_project.md`.

---

## 8. Project Structure

```
my_project/
├── .claude/
├── escalations/
├── howtos/
├── lessons_learned/
├── logs/
├── out/
│   ├── MyProject.Console/
│   │   ├── bin/
│   │   └── obj/
│   ├── MyProject.Core/
│   │   ├── bin/
│   │   └── obj/
│   └── MyProject.Ui/
│       ├── bin/
│       └── obj/
├── resolutions/
├── src/
│   ├── MyProject.Console/
│   │   └── MyProject.Console.csproj
│   ├── MyProject.Core/
│   │   └── MyProject.Core.csproj
│   ├── MyProject.Ui/
│   │   └── MyProject.Ui.csproj
│   ├── tests/
│   │   └── MyProject.IntegrationTests/
│   │       └── MyProject.IntegrationTests.csproj
│   └── MyProject.sln
├── .gitignore
├── prototype.md
└── README.md
```

| Directory/File | Purpose |
|----------------|---------|
| `.claude/` | Claude Code settings and hooks |
| `escalations/` | Problems CC could not solve, to be picked up by Claude.ai |
| `howtos/` | Step-by-step instructions, derived from lessons learned |
| `lessons_learned/` | CC's reports on its own mistakes |
| `logs/` | Runtime logs |
| `out/` | Build output; each project has its own subtree |
| `resolutions/` | Claude.ai answers to escalations, or summaries of spec changes |
| `src/` | Source code; contains .sln and project folders |
| `src/MyProject.Core/` | Shared code (compiles to .dll); referenced by Console and Ui |
| `prototype.md` | Initial intuitions; CC adds Q&A during prototyping phase |
| `README.md` | Empty except reference to prototype.md or high-level spec |

CC must create all directories explicitly.

---

## 9. .gitignore

```
out/
logs/
*.exe
*.dll
*.pdb
*.user
.vs/
```

---

## 10. csproj Settings

### 10.1. Output Paths

Create `src/Directory.Build.props` to keep all build artifacts under `out/`:

```xml
<Project>
  <PropertyGroup>
    <BaseOutputPath>$(MSBuildProjectDirectory)\..\..\out\$(MSBuildProjectName)\bin\</BaseOutputPath>
    <BaseIntermediateOutputPath>$(MSBuildProjectDirectory)\..\..\out\$(MSBuildProjectName)\obj\</BaseIntermediateOutputPath>
  </PropertyGroup>
</Project>
```

This applies to all projects under `src/` automatically. Do not set output paths in individual .csproj files.

### 10.2. Publish Settings

For standalone single-file executables:

```xml
<PropertyGroup>
  <RuntimeIdentifier>win-x64</RuntimeIdentifier>
  <PublishSingleFile>true</PublishSingleFile>
  <SelfContained>true</SelfContained>
  <PublishReadyToRun>true</PublishReadyToRun>
  <IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>
</PropertyGroup>
```

Note: `IncludeNativeLibrariesForSelfExtract` is required — without it, the exe will fail with missing DLL errors.

---

## 11. Build

### 11.1. Output Rule

All compiler-generated files must be under `out/`. Never mixed with source.

### 11.2. Build Script

Build is done using `build.ps1` in project root.

**Usage:**
```
.\build.ps1 -Project <n>
```

**What it does:**
- Updates BuildInfo.cs with timestamp
- Runs `dotnet publish` with required flags
- Copies exe to project root

`build.ps1` is copied from templates during project bootstrap.

Note: `build.ps1` has a `-Run` flag; running is covered in a later chapter.

### 11.3. Exe Location

Only exes for apps (Console, Ui) are copied to project root. Dlls (Core) and test projects stay in `out/` only.

After building everything:
```
my_project/
├── MyProject.Console.exe
├── MyProject.Ui.exe
├── out/
│   ├── MyProject.Console/...
│   ├── MyProject.Core/...
│   ├── MyProject.Ui/...
│   └── MyProject.IntegrationTests/...
```

---

## 12. Working Directory

Every app must have a concept of working directory.

**Default:** Directory where exe is located.

**Override:** Command line parameter `--wd <path>` to specify a different working directory.

All relative paths (logs, config, data) resolve relative to the working directory.

---

## 13. Run

### 13.1. Run Script

Running is done using `run.ps1` in project root.

**Usage:**
```
.\run.ps1 -Project <n>
```

**What it does:**
- Finds exe in project root
- Starts the exe
- Returns PID on success
- Returns error if it fails (exe missing, missing DLLs, etc.)

`run.ps1` is copied from templates during project bootstrap.

### 13.2. Startup Verification

After starting a process, CC must:
1. Verify startup via logs
2. Check logs for any startup errors
3. If errors found:
   - Investigate
   - Discuss with me
   - Propose a fix
4. Confirm explicitly that no errors were found in the logs during startup

A process may start (PID exists) but fail internally. Only proceed after confirming logs show successful startup.

### 13.3. Killing Processes

CC can only kill processes CC started, only by PID. If PID was not captured, ask user to stop manually.

---

## 14. Logging

### 14.1. General

All apps must have logging with variable log level.

### 14.2. Location

Logs go to `logs/` subdirectory (relative to working directory).

### 14.3. File Naming

Log files are named after the project (e.g., `MyProject.Console.log`). This allows multiple apps in the same working directory.

### 14.4. Rotation

On startup, rename existing log to timestamped version. Keep only 3 log files.

If the log file is locked at startup (e.g., user is viewing it), ignore and create a new file.

### 14.5. Format

`[yyyy-MM-dd HH:mm:ss.fff] [LEVEL] Message`

### 14.6. UI Apps

Must have a log panel with the same exact contents as log files.

### 14.7. CLI Apps

Write logs to files only.

---

## 15. Build Number

### 15.1. Format

`YYYY_MM_DD__HH_mm__NNN`

Example: `2025_12_18__14_30__047`

NNN is a build counter that increments every build (never resets).

### 15.2. Generation

Build number is generated by `build.ps1` and written to `BuildInfo.cs`.

### 15.3. UI Apps

Must show build number in the title bar.

### 15.4. CLI Apps

Must display a banner with build number at startup. Must support `--version` flag.

---

## Appendix A. App Creation Checklist

CC must quote each item verbatim, then explain understanding in its own words.

**A.1. Project Structure:**
- A.1.1. All directories created: `.claude/`, `escalations/`, `howtos/`, `lessons_learned/`, `logs/`, `out/`, `resolutions/`, `src/`, `src/tests/`
- A.1.2. `prototype.md` exists
- A.1.3. `README.md` exists with reference to prototype.md
- A.1.4. `.gitignore` exists

**A.2. Source:**
- A.2.1. `.sln` in `src/`
- A.2.2. Each app has its own project folder under `src/`
- A.2.3. `Core` project exists for shared code
- A.2.4. `src/Directory.Build.props` exists with output paths set to `out/`
- A.2.5. Each `.csproj` has publish settings with `IncludeNativeLibrariesForSelfExtract`

**A.3. Working Directory:**
- A.3.1. App has concept of working directory
- A.3.2. Default is directory where exe is located
- A.3.3. `--wd <path>` parameter to override
- A.3.4. All relative paths resolve relative to working directory

**A.4. Build:**
- A.4.1. `build.ps1` in project root
- A.4.2. Build succeeds without errors
- A.4.3. Exe copied to project root

**A.5. Run:**
- A.5.1. `run.ps1` in project root
- A.5.2. App starts successfully
- A.5.3. PID captured
- A.5.4. Logs confirm no startup errors

**A.6. Logging:**
- A.6.1. Logs written to `logs/` (relative to working directory)
- A.6.2. Log files named after project
- A.6.3. Log format correct: `[yyyy-MM-dd HH:mm:ss.fff] [LEVEL] Message`
- A.6.4. UI app: log panel shows same content as log files

**A.7. Build Number:**
- A.7.1. `BuildInfo.cs` exists with current build number
- A.7.2. UI app: build number shown in title bar
- A.7.3. CLI app: banner displays build number at startup
- A.7.4. CLI app: `--version` flag works

---
