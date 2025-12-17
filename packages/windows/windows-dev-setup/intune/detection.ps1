<#
.SYNOPSIS
    Intune Detection Script for Windows Dev Setup

.DESCRIPTION
    This script checks if the application is installed correctly.
    Exit 0 = Installed, Exit 1 = Not Installed
#>

$InstallDir = "$env:ProgramData\WindowsDevSetup"
$ScriptName = "windows-dev-setup.ps1"
$VersionFile = "$InstallDir\version.txt"
$MinVersion = "2.0.0"

# Check if installation directory exists
if (-not (Test-Path $InstallDir)) {
    Write-Host "Installation directory not found"
    exit 1
}

# Check if main script exists
if (-not (Test-Path "$InstallDir\$ScriptName")) {
    Write-Host "Main script not found"
    exit 1
}

# Check if version file exists
if (-not (Test-Path $VersionFile)) {
    Write-Host "Version file not found"
    exit 1
}

# Read version from file
$versionContent = Get-Content $VersionFile -Raw
if ($versionContent -match 'version=(.+)') {
    $installedVersion = $matches[1].Trim()
} else {
    Write-Host "Could not determine installed version"
    exit 1
}

# Check if Start Menu shortcut exists
$startMenuShortcut = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Windows Dev Setup.lnk"
if (-not (Test-Path $startMenuShortcut)) {
    Write-Host "Start Menu shortcut not found"
    exit 1
}

Write-Host "Windows Dev Setup version $installedVersion is installed"
exit 0
