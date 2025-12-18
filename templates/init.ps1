# init.ps1 - Initialize .NET Solution and Projects
# Usage: .\init.ps1 -Name <ProjectPrefix> [-Console] [-Core] [-Ui]
#
# Examples:
#   .\init.ps1 -Name CarpFlow -Console -Core
#   .\init.ps1 -Name MyApp -Console -Core -Ui

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,          # Project prefix (e.g., CarpFlow)
    [switch]$Console,       # Create Console app
    [switch]$Core,          # Create Core class library
    [switch]$Ui             # Create WPF UI app
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$srcDir = Join-Path $projectRoot "src"
$framework = "net10.0"

# Validate at least one project type selected
if (-not $Console -and -not $Core -and -not $Ui) {
    Write-Host "ERROR: Specify at least one project type: -Console, -Core, -Ui" -ForegroundColor Red
    exit 1
}

Write-Host "=== Init Script ===" -ForegroundColor Cyan
Write-Host "Name: $Name"
Write-Host "Framework: $framework"

# Create solution
$slnPath = Join-Path $srcDir "$Name.sln"
if (Test-Path $slnPath) {
    Write-Host "Solution already exists: $slnPath" -ForegroundColor Yellow
} else {
    Write-Host "Creating solution..."
    dotnet new sln -n $Name -o $srcDir
}

# Create Core library
if ($Core) {
    $corePath = Join-Path $srcDir "$Name.Core"
    if (Test-Path $corePath) {
        Write-Host "Core project already exists" -ForegroundColor Yellow
    } else {
        Write-Host "Creating $Name.Core..."
        dotnet new classlib -n "$Name.Core" -f $framework -o $corePath
        dotnet sln $slnPath add "$corePath\$Name.Core.csproj"
    }
}

# Create Console app
if ($Console) {
    $consolePath = Join-Path $srcDir "$Name.Console"
    if (Test-Path $consolePath) {
        Write-Host "Console project already exists" -ForegroundColor Yellow
    } else {
        Write-Host "Creating $Name.Console..."
        dotnet new console -n "$Name.Console" -f $framework -o $consolePath
        dotnet sln $slnPath add "$consolePath\$Name.Console.csproj"
        if ($Core) {
            dotnet add "$consolePath\$Name.Console.csproj" reference "$srcDir\$Name.Core\$Name.Core.csproj"
        }
    }
}

# Create WPF UI app
if ($Ui) {
    $uiPath = Join-Path $srcDir "$Name.Ui"
    if (Test-Path $uiPath) {
        Write-Host "UI project already exists" -ForegroundColor Yellow
    } else {
        Write-Host "Creating $Name.Ui..."
        dotnet new wpf -n "$Name.Ui" -f "$framework-windows" -o $uiPath
        dotnet sln $slnPath add "$uiPath\$Name.Ui.csproj"
        if ($Core) {
            dotnet add "$uiPath\$Name.Ui.csproj" reference "$srcDir\$Name.Core\$Name.Core.csproj"
        }
    }
}

Write-Host "SUCCESS: Solution initialized" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Add publish settings to .csproj files"
Write-Host "  2. Create BuildInfo.cs in app projects"
Write-Host "  3. Run: .\build.ps1 -Project <name>"
