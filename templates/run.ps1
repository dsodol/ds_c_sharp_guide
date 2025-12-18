# Run Script for .NET Projects
# Usage: .\run.ps1 -Project <name>

param(
    [Parameter(Mandatory=$true)]
    [string]$Project
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$exePath = Join-Path $projectRoot "$Project.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: $Project.exe not found in project root" -ForegroundColor Red
    exit 1
}

Write-Host "Starting $Project.exe..." -ForegroundColor Yellow
try {
    $proc = Start-Process -FilePath $exePath -PassThru
    Write-Host "PID: $($proc.Id)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to start $Project.exe - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
