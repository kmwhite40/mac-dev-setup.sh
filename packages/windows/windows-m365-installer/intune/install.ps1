<#
.SYNOPSIS
    Intune Installation Wrapper for Microsoft 365 Installer

.DESCRIPTION
    This script is designed to be deployed via Microsoft Intune as a Win32 app.
    It downloads and executes the M365 installer with full logging and error handling.

.NOTES
    Version: 1.2.0
    Company: SBS Federal
    Author: IT Department
    Contact: it@sbsfederal.com

.INTUNE DEPLOYMENT
    Install command: powershell.exe -ExecutionPolicy Bypass -File install.ps1
    Uninstall command: powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1
    Detection: Use detection.ps1 or registry key check
#>

#Requires -RunAsAdministrator

# Configuration
$Script:Version = "1.2.0"
$Script:CompanyName = "SBS Federal"
$Script:PackageName = "M365-Installer"
$Script:InstallDir = "$env:ProgramFiles\SBSFederal\M365Installer"
$Script:LogDir = "$env:ProgramData\SBSFederal\M365Installer\Logs"
$Script:LogFile = "$Script:LogDir\intune-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Script:RegistryPath = "HKLM:\SOFTWARE\SBSFederal\M365Installer"

# Ensure directories exist
if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
}

if (-not (Test-Path $Script:InstallDir)) {
    New-Item -ItemType Directory -Path $Script:InstallDir -Force | Out-Null
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

    # Write to log file
    Add-Content -Path $Script:LogFile -Value $logMessage

    # Also write to console for Intune logging
    Write-Host $logMessage
}

# Main installation function
function Start-IntuneInstallation {
    Write-Log "============================================" -Level INFO
    Write-Log "SBS Federal M365 Installer - Intune Deployment" -Level INFO
    Write-Log "Version: $Script:Version" -Level INFO
    Write-Log "============================================" -Level INFO

    try {
        # Check if main script exists in package
        $mainScript = Join-Path $PSScriptRoot "..\scripts\windows-m365-installer.ps1"

        if (-not (Test-Path $mainScript)) {
            # Try alternate path (if script is in same directory)
            $mainScript = Join-Path $PSScriptRoot "windows-m365-installer.ps1"
        }

        if (-not (Test-Path $mainScript)) {
            Write-Log "Main installer script not found at expected locations" -Level ERROR
            Write-Log "Expected: $mainScript" -Level ERROR
            exit 1
        }

        Write-Log "Found installer script: $mainScript" -Level INFO

        # Copy script to installation directory
        $installedScript = Join-Path $Script:InstallDir "windows-m365-installer.ps1"
        Copy-Item -Path $mainScript -Destination $installedScript -Force
        Write-Log "Copied installer to: $installedScript" -Level SUCCESS

        # Execute the main installer
        Write-Log "Starting M365 installation..." -Level INFO

        $process = Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$installedScript`"" `
            -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Log "M365 installation completed successfully" -Level SUCCESS

            # Create registry entry for detection
            Set-RegistryDetection

            exit 0
        } elseif ($process.ExitCode -eq 3010) {
            Write-Log "M365 installation completed - restart required" -Level WARNING
            Set-RegistryDetection
            exit 3010  # Soft reboot required
        } else {
            Write-Log "M365 installation failed with exit code: $($process.ExitCode)" -Level ERROR
            exit $process.ExitCode
        }

    } catch {
        Write-Log "Unexpected error during installation: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        exit 1
    }
}

# Create registry detection key
function Set-RegistryDetection {
    try {
        if (-not (Test-Path $Script:RegistryPath)) {
            New-Item -Path $Script:RegistryPath -Force | Out-Null
        }

        Set-ItemProperty -Path $Script:RegistryPath -Name "Version" -Value $Script:Version -Type String
        Set-ItemProperty -Path $Script:RegistryPath -Name "InstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String
        Set-ItemProperty -Path $Script:RegistryPath -Name "InstallPath" -Value $Script:InstallDir -Type String
        Set-ItemProperty -Path $Script:RegistryPath -Name "Company" -Value $Script:CompanyName -Type String

        Write-Log "Registry detection key created at: $Script:RegistryPath" -Level SUCCESS
    } catch {
        Write-Log "Warning: Could not create registry detection key: $_" -Level WARNING
    }
}

# Run installation
Start-IntuneInstallation
