<#
.SYNOPSIS
    Intune Uninstallation Script for Windows Dev Setup

.DESCRIPTION
    This script is called by Intune when uninstalling the application.
#>

#Requires -RunAsAdministrator

# Configuration
$InstallDir = "$env:ProgramData\WindowsDevSetup"
$LogDir = "$env:ProgramData\WindowsDevSetup\Logs"
$IntuneLog = "$LogDir\intune-uninstall.log"

# Logging function
function Write-IntuneLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    if (Test-Path $LogDir) {
        Add-Content -Path $IntuneLog -Value $logMessage
    }
    Write-Host $logMessage
}

Write-IntuneLog "========================================="
Write-IntuneLog "Windows Dev Setup - Uninstallation"
Write-IntuneLog "========================================="

try {
    # Remove Start Menu shortcut
    $startMenuShortcut = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Windows Dev Setup.lnk"
    if (Test-Path $startMenuShortcut) {
        Write-IntuneLog "Removing Start Menu shortcut..."
        Remove-Item -Path $startMenuShortcut -Force
        Write-IntuneLog "Start Menu shortcut removed"
    }

    # Remove desktop shortcut
    $publicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
    $desktopShortcut = "$publicDesktop\Windows Dev Setup.lnk"
    if (Test-Path $desktopShortcut) {
        Write-IntuneLog "Removing desktop shortcut..."
        Remove-Item -Path $desktopShortcut -Force
        Write-IntuneLog "Desktop shortcut removed"
    }

    # Remove installation directory
    if (Test-Path $InstallDir) {
        Write-IntuneLog "Removing installation directory..."
        # Keep logs for audit trail
        $tempLogDir = "$env:TEMP\WindowsDevSetup_Logs"
        if (Test-Path $LogDir) {
            Copy-Item -Path $LogDir -Destination $tempLogDir -Recurse -Force
            Write-IntuneLog "Logs backed up to: $tempLogDir"
        }
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-IntuneLog "Installation directory removed"
    }

    Write-IntuneLog "========================================="
    Write-IntuneLog "Uninstallation Complete"
    Write-IntuneLog "========================================="
    Write-IntuneLog "Note: Installed applications were NOT removed"
    Write-IntuneLog "To remove installed apps, use Windows Settings or:"
    Write-IntuneLog "  choco uninstall <package-name>"
    Write-IntuneLog ""
    Write-IntuneLog "Backup logs location: $tempLogDir"

    exit 0

} catch {
    Write-IntuneLog "ERROR: Uninstallation failed: $_"
    exit 1
}
