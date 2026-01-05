<#
.SYNOPSIS
    Intune Detection Script for Microsoft 365 Installer

.DESCRIPTION
    This script detects if the M365 Installer package has been successfully deployed.
    Used by Intune to determine installation status.

.NOTES
    Version: 1.2.0
    Company: SBS Federal
    Author: IT Department
    Contact: it@sbsfederal.com

.INTUNE DETECTION RULES
    Rule type: Custom detection script
    Script file: detection.ps1
    Run script as 32-bit process: No
    Enforce script signature check: No (or Yes if signed)
    Run script in 64-bit PowerShell: Yes

.OUTPUT
    - Exit code 0 + output = Detected (installed)
    - Exit code 0 + no output = Not detected (not installed)
    - Exit code non-zero = Detection error
#>

# Configuration
$Script:RegistryPath = "HKLM:\SOFTWARE\SBSFederal\M365Installer"
$Script:MinVersion = "1.0.0"

# Detection Method 1: Registry Key
function Test-RegistryDetection {
    try {
        if (Test-Path $Script:RegistryPath) {
            $version = (Get-ItemProperty -Path $Script:RegistryPath -Name Version -ErrorAction SilentlyContinue).Version
            if ($version) {
                return @{
                    Detected = $true
                    Version = $version
                    Method = "Registry"
                }
            }
        }
    } catch {
        # Silently continue to next detection method
    }

    return @{ Detected = $false; Method = "Registry" }
}

# Detection Method 2: Check for installed Office applications
function Test-OfficeDetection {
    $officeApps = @(
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    )

    foreach ($path in $officeApps) {
        if (Test-Path $path) {
            $version = (Get-ItemProperty -Path $path -Name VersionToReport -ErrorAction SilentlyContinue).VersionToReport
            if ($version) {
                return @{
                    Detected = $true
                    Version = $version
                    Method = "Office365"
                }
            }
        }
    }

    return @{ Detected = $false; Method = "Office365" }
}

# Detection Method 3: Check for Teams
function Test-TeamsDetection {
    $teamsPath = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $teamsPath) {
        $version = (Get-Item $teamsPath).VersionInfo.FileVersion
        return @{
            Detected = $true
            Version = $version
            Method = "Teams"
        }
    }

    return @{ Detected = $false; Method = "Teams" }
}

# Detection Method 4: Check for OneDrive
function Test-OneDriveDetection {
    $onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    if (Test-Path $onedrivePath) {
        $version = (Get-Item $onedrivePath).VersionInfo.FileVersion
        return @{
            Detected = $true
            Version = $version
            Method = "OneDrive"
        }
    }

    return @{ Detected = $false; Method = "OneDrive" }
}

# Main detection logic
function Start-Detection {
    # Primary detection: Registry key (indicates our installer ran)
    $registryResult = Test-RegistryDetection
    if ($registryResult.Detected) {
        # Output detected - this tells Intune the app is installed
        Write-Output "M365 Installer detected via registry. Version: $($registryResult.Version)"
        exit 0
    }

    # Secondary detection: Check if Office is installed (may have been installed by our tool)
    $officeResult = Test-OfficeDetection
    $teamsResult = Test-TeamsDetection
    $onedriveResult = Test-OneDriveDetection

    # Count installed components
    $installedCount = 0
    if ($officeResult.Detected) { $installedCount++ }
    if ($teamsResult.Detected) { $installedCount++ }
    if ($onedriveResult.Detected) { $installedCount++ }

    # If at least 2 of 3 key components are installed, consider it detected
    if ($installedCount -ge 2) {
        Write-Output "M365 applications detected. Office: $($officeResult.Detected), Teams: $($teamsResult.Detected), OneDrive: $($onedriveResult.Detected)"
        exit 0
    }

    # Not detected - no output, exit 0
    exit 0
}

# Run detection
Start-Detection
