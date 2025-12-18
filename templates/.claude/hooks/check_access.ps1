# Portable directory access whitelist hook for Claude Code.
# Blocks file operations outside allowed directories.
# Copy .claude/ folder to any project - works without modification.

$ErrorActionPreference = "Stop"

# Set to $true to enable debug logging
$DebugLogging = $false

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir "hook_debug.log"

function Write-Log {
    param([string]$msg)
    if (-not $DebugLogging) { return }
    $timestamp = Get-Date -Format "HH:mm:ss"
    "$timestamp - $msg" | Out-File -FilePath $logFile -Append
}
$projectDir = $env:CLAUDE_PROJECT_DIR
$settingsFile = Join-Path $projectDir ".claude\settings.json"
$whitelistFile = Join-Path $scriptDir "whitelist.txt"

# Bash commands that take file/dir arguments
$fileCommands = @("cd", "cat", "type", "dir", "ls", "more", "less", "head", "tail", "cp", "mv", "rm")

function Get-Whitelist {
    $whitelist = @()

    # 1. Always include current project directory
    if ($projectDir) {
        $whitelist += $projectDir.ToLower()
    }

    # 2. Read additionalDirectories from settings.json
    if (Test-Path $settingsFile) {
        try {
            $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
            $additionalDirs = $settings.permissions.additionalDirectories
            if ($additionalDirs) {
                foreach ($dir in $additionalDirs) {
                    # Resolve relative paths from project directory
                    $resolved = [System.IO.Path]::GetFullPath((Join-Path $projectDir $dir))
                    $whitelist += $resolved.ToLower()
                }
            }
        } catch {
            # Ignore JSON parse errors, continue with project dir only
        }
    }

    # 3. Read optional whitelist.txt for extra paths
    if (Test-Path $whitelistFile) {
        $lines = Get-Content $whitelistFile | Where-Object { $_.Trim() -and -not $_.StartsWith("#") }
        foreach ($line in $lines) {
            $path = $line.Trim()
            # Resolve relative paths from project directory
            if (-not [System.IO.Path]::IsPathRooted($path)) {
                $path = [System.IO.Path]::GetFullPath((Join-Path $projectDir $path))
            }
            $whitelist += $path.ToLower()
        }
    }

    return $whitelist
}

function Resolve-NormalizedPath {
    param([string]$path)
    try {
        $resolved = [System.IO.Path]::GetFullPath($path)
        return $resolved.ToLower()
    } catch {
        return $path.ToLower()
    }
}

function Test-PathAllowed {
    param([string]$path, [string[]]$whitelist)
    $normalized = Resolve-NormalizedPath $path
    foreach ($w in $whitelist) {
        if ($normalized.StartsWith($w)) {
            return $true
        }
    }
    return $false
}

function Get-PathsFromBash {
    param([string]$command)
    $paths = @()
    foreach ($cmd in $fileCommands) {
        $pattern = "\b$cmd\s+[`"']?([^`"';&|>\n]+)[`"']?"
        $regexMatches = [regex]::Matches($command, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $regexMatches) {
            $path = $match.Groups[1].Value.Trim()
            if ($path -and -not $path.StartsWith("-")) {
                $paths += $path
            }
        }
    }
    return $paths
}

# Validate environment
if (-not $projectDir) {
    Write-Error "CLAUDE_PROJECT_DIR not set"
    exit 2
}

# Read JSON from stdin
$inputJson = [Console]::In.ReadToEnd()
Write-Log "Hook started"
try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    Write-Log "Invalid JSON: $_"
    Write-Error "Invalid JSON input: $_"
    exit 1
}

$tool = $data.tool_name
$inputs = $data.tool_input
$whitelist = Get-Whitelist
Write-Log "Tool: $tool | Input: $($inputs | ConvertTo-Json -Compress)"

function Block-Tool {
    param([string]$reason)
    Write-Log "BLOCKED: $reason"
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = $reason
        }
    }
    $output | ConvertTo-Json -Depth 3
    exit 0
}

# File tools - check file_path parameter
if ($tool -in @("Read", "Edit", "Write")) {
    $path = $inputs.file_path
    if ($path -and -not (Test-PathAllowed $path $whitelist)) {
        Block-Tool "Path not in whitelist: $path"
    }
}
# Search tools - check path parameter
elseif ($tool -in @("Glob", "Grep")) {
    $path = $inputs.path
    if (-not $path) { $path = $projectDir }
    if (-not (Test-PathAllowed $path $whitelist)) {
        Block-Tool "Path not in whitelist: $path"
    }
}
# Bash - parse command for file paths
elseif ($tool -eq "Bash") {
    $command = $inputs.command
    $paths = Get-PathsFromBash $command
    Write-Log "Bash paths extracted: $($paths -join ', ')"
    foreach ($path in $paths) {
        # Skip relative paths that stay within project
        if ($path.StartsWith("./") -or $path.StartsWith(".\")) {
            Write-Log "Skipping relative: $path"
            continue
        }
        # Check absolute paths and parent references
        if ([System.IO.Path]::IsPathRooted($path) -or $path.Contains("..")) {
            Write-Log "Checking path: $path | Rooted: $([System.IO.Path]::IsPathRooted($path))"
            if (-not (Test-PathAllowed $path $whitelist)) {
                Block-Tool "Bash accessing path not in whitelist: $path"
            }
        } else {
            Write-Log "Skipping non-rooted: $path"
        }
    }
}

# Allow by default
Write-Log "ALLOWED"
exit 0
