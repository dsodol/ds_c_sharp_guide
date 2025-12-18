# Run Script for .NET Projects
# Usage: .\run.ps1 -Project <n> [-Args <arguments>] [-Wait]

param(
    [Parameter(Mandatory=$true)]
    [string]$Project,
    [string]$Args = "",
    [switch]$Wait    # Run synchronously and capture output
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$exePath = Join-Path $projectRoot "$Project.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: $Project.exe not found in project root" -ForegroundColor Red
    exit 1
}

if ($Wait) {
    # Run synchronously, capture output
    Write-Host "Running $Project.exe..." -ForegroundColor Yellow
    if ($Args) {
        & $exePath $Args.Split(' ')
    } else {
        & $exePath
    }
} else {
    # Run asynchronously, return PID
    Write-Host "Starting $Project.exe..." -ForegroundColor Yellow
    try {
        if ($Args) {
            $proc = Start-Process -FilePath $exePath -ArgumentList $Args -PassThru
        } else {
            $proc = Start-Process -FilePath $exePath -PassThru
        }
        Write-Host "PID: $($proc.Id)" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to start $Project.exe - $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
