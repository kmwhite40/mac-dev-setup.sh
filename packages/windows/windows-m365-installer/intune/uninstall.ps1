<#
.SYNOPSIS
    Intune Uninstallation Script for Microsoft 365 Installer

.DESCRIPTION
    This script removes the M365 Installer package from the system.
    Note: This does NOT uninstall the M365 applications themselves.

.NOTES
    Version: 1.2.0
    Company: SBS Federal
    Author: IT Department
    Contact: it@sbsfederal.com

.INTUNE DEPLOYMENT
    Uninstall command: powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1
#>

#Requires -RunAsAdministrator

# Configuration
$Script:InstallDir = "$env:ProgramFiles\SBSFederal\M365Installer"
$Script:LogDir = "$env:ProgramData\SBSFederal\M365Installer\Logs"
$Script:LogFile = "$Script:LogDir\intune-uninstall-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Script:RegistryPath = "HKLM:\SOFTWARE\SBSFederal\M365Installer"

# Ensure log directory exists
if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $Script:LogFile -Value $logMessage
    Write-Host $logMessage
}

# Main uninstallation function
function Start-IntuneUninstallation {
    Write-Log "============================================" -Level INFO
    Write-Log "SBS Federal M365 Installer - Uninstallation" -Level INFO
    Write-Log "============================================" -Level INFO

    $success = $true

    try {
        # Remove installation directory
        if (Test-Path $Script:InstallDir) {
            Write-Log "Removing installation directory: $Script:InstallDir" -Level INFO
            Remove-Item -Path $Script:InstallDir -Recurse -Force -ErrorAction Stop
            Write-Log "Installation directory removed" -Level SUCCESS
        } else {
            Write-Log "Installation directory not found (already removed)" -Level INFO
        }

        # Remove registry key
        if (Test-Path $Script:RegistryPath) {
            Write-Log "Removing registry key: $Script:RegistryPath" -Level INFO
            Remove-Item -Path $Script:RegistryPath -Recurse -Force -ErrorAction Stop
            Write-Log "Registry key removed" -Level SUCCESS
        } else {
            Write-Log "Registry key not found (already removed)" -Level INFO
        }

        # Note: We do NOT remove M365 applications
        Write-Log "" -Level INFO
        Write-Log "NOTE: Microsoft 365 applications have NOT been removed." -Level WARNING
        Write-Log "To uninstall Office apps, use the Office Deployment Tool or" -Level INFO
        Write-Log "uninstall them individually from Settings > Apps." -Level INFO

        Write-Log "" -Level INFO
        Write-Log "Uninstallation completed successfully" -Level SUCCESS
        exit 0

    } catch {
        Write-Log "Error during uninstallation: $_" -Level ERROR
        exit 1
    }
}

# Run uninstallation
Start-IntuneUninstallation
