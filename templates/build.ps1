# Universal Build Script for .NET Projects
# Usage: .\build.ps1 [-Project <name>] [-Run]

param(
    [string]$Project,  # Project name (without .csproj)
    [switch]$Run       # Start the app after build and output PID
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$srcDir = Join-Path $projectRoot "src"

# Find .csproj files (src/*.csproj and src/*/*.csproj)
$csprojFiles = @()
$csprojFiles += Get-ChildItem -Path $srcDir -Filter "*.csproj" -ErrorAction SilentlyContinue
$csprojFiles += Get-ChildItem -Path $srcDir -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter "*.csproj" -ErrorAction SilentlyContinue }

if ($csprojFiles.Count -eq 0) {
    Write-Host "ERROR: No .csproj files found in $srcDir" -ForegroundColor Red
    exit 1
}

# Select project
if ($Project) {
    $csproj = $csprojFiles | Where-Object { $_.BaseName -eq $Project } | Select-Object -First 1
    if (-not $csproj) {
        Write-Host "ERROR: Project '$Project' not found. Available:" -ForegroundColor Red
        $csprojFiles | ForEach-Object { Write-Host "  - $($_.BaseName)" }
        exit 1
    }
} elseif ($csprojFiles.Count -eq 1) {
    $csproj = $csprojFiles[0]
} else {
    Write-Host "ERROR: Multiple projects found. Specify with -Project:" -ForegroundColor Red
    $csprojFiles | ForEach-Object { Write-Host "  - $($_.BaseName)" }
    exit 1
}

$projectName = $csproj.BaseName
$csprojPath = $csproj.FullName
$csprojDir = $csproj.DirectoryName

# Detect target framework
$csprojContent = Get-Content $csprojPath -Raw
if ($csprojContent -match '<TargetFramework>([^<]+)</TargetFramework>') {
    $targetFramework = $matches[1]
} else {
    Write-Host "ERROR: Could not detect TargetFramework" -ForegroundColor Red
    exit 1
}

# Build paths
$buildInfoPath = Join-Path $csprojDir "BuildInfo.cs"
$publishDir = Join-Path $projectRoot "out\bin\Debug\$targetFramework\win-x64\publish"
$exeName = "$projectName.exe"

# Generate build number
$timestamp = Get-Date -Format "yyyy_MM_dd__HH_mm"
$buildNumber = "${timestamp}__001"

Write-Host "=== Build Script ===" -ForegroundColor Cyan
Write-Host "Project: $projectName"
Write-Host "Framework: $targetFramework"
Write-Host "Build: $buildNumber"

# Update BuildInfo.cs if exists
if (Test-Path $buildInfoPath) {
    Write-Host "Updating BuildInfo.cs..."
    $content = Get-Content $buildInfoPath -Raw
    $content = $content -replace 'Number = "[^"]+"', "Number = `"$buildNumber`""
    Set-Content -Path $buildInfoPath -Value $content -NoNewline -Encoding UTF8
}

# Publish
Write-Host "Publishing..."
dotnet publish $csprojPath -c Debug -r win-x64 --self-contained true -p:PublishSingleFile=true
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Publish failed" -ForegroundColor Red
    exit 1
}

# Copy exe to project root
$sourceExe = Join-Path $publishDir $exeName
$destExe = Join-Path $projectRoot $exeName
Write-Host "Copying $exeName to project root..."
Copy-Item -Path $sourceExe -Destination $destExe -Force

# Verify
if (Test-Path $destExe) {
    Write-Host "SUCCESS: $destExe" -ForegroundColor Green
} else {
    Write-Host "ERROR: Exe not found" -ForegroundColor Red
    exit 1
}

# Optionally run
if ($Run) {
    Write-Host "Starting $exeName..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath $destExe -PassThru
    Write-Host "PID: $($proc.Id)" -ForegroundColor Green
}
