<#
.SYNOPSIS
    Intune Installation Script for Windows Dev Setup

.DESCRIPTION
    This script is called by Intune when deploying the Windows Dev Setup package.
    Installs the script system-wide and creates command-line wrapper.
#>

#Requires -RunAsAdministrator

# Configuration
$InstallDir = "$env:ProgramData\WindowsDevSetup"
$LogDir = "$env:ProgramData\WindowsDevSetup\Logs"
$IntuneLog = "$LogDir\intune-install.log"
$ScriptName = "windows-dev-setup.ps1"
$Version = "2.0.0"
$CompanyName = "SBS Federal"
$ITSupportEmail = "it@sbsfederal.com"
$UpdateIntervalDays = 4

# Create directories
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# Logging function
function Write-IntuneLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $IntuneLog -Value $logMessage
    Write-Host $logMessage
}

Write-IntuneLog "========================================="
Write-IntuneLog "Windows Dev Setup - Intune Installation"
Write-IntuneLog "========================================="

try {
    # Copy main script to installation directory
    Write-IntuneLog "Copying main script to $InstallDir..."
    $sourcePath = Join-Path $PSScriptRoot $ScriptName
    $destPath = Join-Path $InstallDir $ScriptName

    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-IntuneLog "Main script copied successfully"
    } else {
        Write-IntuneLog "ERROR: Source script not found at $sourcePath"
        exit 1
    }

    # Create version file
    Write-IntuneLog "Creating version file..."
    $versionContent = @"
version=$Version
installed=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
company=$CompanyName
"@
    $versionContent | Out-File -FilePath "$InstallDir\version.txt" -Force
    Write-IntuneLog "Version file created"

    # Create company config file
    Write-IntuneLog "Creating configuration file..."
    $configContent = @"
# Windows Dev Setup Configuration
`$CompanyName = "$CompanyName"
`$ITSupportEmail = "$ITSupportEmail"
`$UpdateIntervalDays = $UpdateIntervalDays
`$SkipWindowsUpdates = `$false
`$EnableLogging = `$true
"@
    $configContent | Out-File -FilePath "$InstallDir\config.ps1" -Force
    Write-IntuneLog "Configuration file created"

    # Create command-line wrapper script
    Write-IntuneLog "Creating command-line wrapper..."
    $wrapperContent = @"
<#
.SYNOPSIS
    Windows Dev Setup launcher script
#>

`$ScriptPath = "$InstallDir\$ScriptName"

if (Test-Path `$ScriptPath) {
    & powershell.exe -ExecutionPolicy Bypass -NoProfile -File `$ScriptPath
} else {
    Write-Error "Windows Dev Setup not found at `$ScriptPath"
    exit 1
}
"@
    $wrapperPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Windows Dev Setup.lnk"
    $wrapperContent | Out-File -FilePath "$InstallDir\launcher.ps1" -Force

    # Create Start Menu shortcut
    Write-IntuneLog "Creating Start Menu shortcut..."
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Windows Dev Setup.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$InstallDir\launcher.ps1`""
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.Description = "SBS Federal Windows Developer Environment Setup"
    $shortcut.Save()
    Write-IntuneLog "Start Menu shortcut created"

    # Create desktop shortcut for all users
    Write-IntuneLog "Creating desktop shortcut..."
    $publicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
    $desktopShortcut = $shell.CreateShortcut("$publicDesktop\Windows Dev Setup.lnk")
    $desktopShortcut.TargetPath = "powershell.exe"
    $desktopShortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$InstallDir\launcher.ps1`""
    $desktopShortcut.WorkingDirectory = $InstallDir
    $desktopShortcut.Description = "SBS Federal Windows Developer Environment Setup"
    $desktopShortcut.Save()
    Write-IntuneLog "Desktop shortcut created"

    # Set permissions
    Write-IntuneLog "Setting file permissions..."
    $acl = Get-Acl $InstallDir
    $acl.SetAccessRuleProtection($false, $true)
    Set-Acl -Path $InstallDir -AclObject $acl
    Write-IntuneLog "Permissions set"

    Write-IntuneLog "========================================="
    Write-IntuneLog "Installation Complete"
    Write-IntuneLog "========================================="
    Write-IntuneLog "Installed to: $InstallDir"
    Write-IntuneLog "Version: $Version"
    Write-IntuneLog "Log file: $IntuneLog"
    Write-IntuneLog ""
    Write-IntuneLog "Users can now run the setup from:"
    Write-IntuneLog "- Start Menu: Windows Dev Setup"
    Write-IntuneLog "- Desktop: Windows Dev Setup shortcut"
    Write-IntuneLog "- PowerShell: & '$InstallDir\$ScriptName'"

    exit 0

} catch {
    Write-IntuneLog "ERROR: Installation failed: $_"
    exit 1
}
