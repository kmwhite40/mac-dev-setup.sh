<#
.SYNOPSIS
    Microsoft 365 Installer for Windows

.DESCRIPTION
    Automated installer for Microsoft 365 applications on Windows endpoints.
    Downloads and installs Office Suite, Teams, OneDrive, Edge, and Company Portal.
    Designed for SBS Federal - Enterprise-grade deployment with comprehensive logging.

.NOTES
    Version: 1.0.0
    Company: SBS Federal
    Author: IT Department
    Contact: it@sbsfederal.com

.FEATURES
    - Automatic download from Microsoft CDN
    - Installs Office Suite (Word, Excel, PowerPoint, Outlook, OneNote)
    - Installs Teams, OneDrive, Edge, Company Portal
    - Smart detection of existing installations
    - Desktop shortcuts creation
    - Comprehensive logging
    - Intune-ready deployment
#>

#Requires -RunAsAdministrator

# Script configuration
$Script:Version = "1.0.0"
$Script:CompanyName = "SBS Federal"
$Script:ITSupportEmail = "it@sbsfederal.com"
$Script:LogDir = "$env:USERPROFILE\.m365-installer"
$Script:LogFile = "$Script:LogDir\installer.log"
$Script:DownloadDir = "$Script:LogDir\downloads"

# Statistics
$Script:TotalApps = 0
$Script:SuccessCount = 0
$Script:SkippedCount = 0
$Script:FailedCount = 0

# Microsoft 365 download URLs (official CDN links)
$Script:M365Downloads = @{
    "Office365" = @{
        Name = "Microsoft Office 365"
        URL = "https://go.microsoft.com/fwlink/?linkid=2139145"  # Office Deployment Tool
        FileName = "office365.exe"
        ConfigRequired = $true
    }
    "Teams" = @{
        Name = "Microsoft Teams"
        URL = "https://go.microsoft.com/fwlink/?linkid=2187327&Lmsrc=groupChatMarketingPageWeb&Cmpid=directDownloadWin64"
        FileName = "Teams_windows_x64.exe"
        ConfigRequired = $false
    }
    "OneDrive" = @{
        Name = "Microsoft OneDrive"
        URL = "https://go.microsoft.com/fwlink/?linkid=844652"
        FileName = "OneDriveSetup.exe"
        ConfigRequired = $false
    }
    "Edge" = @{
        Name = "Microsoft Edge"
        URL = "https://go.microsoft.com/fwlink/?linkid=2108834&Channel=Stable&language=en"
        FileName = "MicrosoftEdgeEnterpriseX64.msi"
        ConfigRequired = $false
    }
    "CompanyPortal" = @{
        Name = "Company Portal"
        URL = "https://go.microsoft.com/fwlink/?linkid=2163228"
        FileName = "CompanyPortal.exe"
        ConfigRequired = $false
    }
    "Netskope" = @{
        Name = "Netskope Client"
        URL = "https://addon-sgn.netskope.com/client/NSClient.exe"
        FileName = "NSClient.exe"
        ConfigRequired = $false
    }
}

# Create directories
if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
}

if (-not (Test-Path $Script:DownloadDir)) {
    New-Item -ItemType Directory -Path $Script:DownloadDir -Force | Out-Null
}

# Logging functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'INFO'    { Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
        'SUCCESS' { Write-Host "✅ $Message" -ForegroundColor Green }
        'WARNING' { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        'ERROR'   { Write-Host "❌ $Message" -ForegroundColor Red }
    }

    Add-Content -Path $Script:LogFile -Value $logMessage
}

function Write-Header {
    param([string]$Text)

    $separator = "=" * 60
    Write-Log $separator -Level INFO
    Write-Log $Text -Level INFO
    Write-Log $separator -Level INFO
}

# Check if application is installed
function Test-M365AppInstalled {
    param([string]$AppName)

    switch ($AppName) {
        "Office365" {
            # Check for Office installation
            $officePaths = @(
                "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
            )
            foreach ($path in $officePaths) {
                if (Test-Path $path) {
                    $version = (Get-ItemProperty -Path $path -Name VersionToReport -ErrorAction SilentlyContinue).VersionToReport
                    if ($version) {
                        return $version
                    }
                }
            }
            return $null
        }
        "Teams" {
            $teamsPath = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
            if (Test-Path $teamsPath) {
                return (Get-Item $teamsPath).VersionInfo.FileVersion
            }
            return $null
        }
        "OneDrive" {
            $onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
            if (Test-Path $onedrivePath) {
                return (Get-Item $onedrivePath).VersionInfo.FileVersion
            }
            return $null
        }
        "Edge" {
            $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
            if (Test-Path $edgePath) {
                return (Get-Item $edgePath).VersionInfo.FileVersion
            }
            return $null
        }
        "CompanyPortal" {
            # Check installed apps
            $portal = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue
            if ($portal) {
                return $portal.Version
            }
            return $null
        }
        "Netskope" {
            # Check for Netskope Client installation
            $netskopePaths = @(
                "$env:ProgramFiles\Netskope\STAgent\stAgentSvc.exe",
                "${env:ProgramFiles(x86)}\Netskope\STAgent\stAgentSvc.exe"
            )
            foreach ($path in $netskopePaths) {
                if (Test-Path $path) {
                    return (Get-Item $path).VersionInfo.FileVersion
                }
            }
            # Also check registry
            $regPath = "HKLM:\SOFTWARE\Netskope\STAgent"
            if (Test-Path $regPath) {
                $version = (Get-ItemProperty -Path $regPath -Name Version -ErrorAction SilentlyContinue).Version
                if ($version) {
                    return $version
                }
            }
            return $null
        }
    }

    return $null
}

# Download file
function Get-M365File {
    param(
        [string]$URL,
        [string]$FilePath,
        [string]$AppName
    )

    try {
        Write-Log "Downloading $AppName..." -Level INFO
        Write-Log "URL: $URL" -Level INFO

        # Use BITS for reliable download
        $bitsJob = Start-BitsTransfer -Source $URL -Destination $FilePath -DisplayName $AppName -Description "Downloading $AppName" -ErrorAction Stop

        if (Test-Path $FilePath) {
            $fileSize = [math]::Round((Get-Item $FilePath).Length / 1MB, 2)
            Write-Log "Downloaded $AppName ($fileSize MB)" -Level SUCCESS
            return $true
        } else {
            Write-Log "Failed to download $AppName" -Level ERROR
            return $false
        }
    } catch {
        Write-Log "Error downloading $AppName: $_" -Level ERROR
        return $false
    }
}

# Install application
function Install-M365App {
    param(
        [string]$AppKey,
        [hashtable]$AppInfo
    )

    $Script:TotalApps++
    Write-Header "Installing $($AppInfo.Name)"

    # Check if already installed
    $installedVersion = Test-M365AppInstalled -AppName $AppKey

    if ($installedVersion) {
        Write-Log "$($AppInfo.Name) is already installed (version: $installedVersion)" -Level WARNING
        Write-Log "Skipping installation" -Level WARNING
        $Script:SkippedCount++
        return
    }

    # Download file
    $filePath = Join-Path $Script:DownloadDir $AppInfo.FileName

    if (-not (Test-Path $filePath)) {
        $downloadSuccess = Get-M365File -URL $AppInfo.URL -FilePath $filePath -AppName $AppInfo.Name

        if (-not $downloadSuccess) {
            $Script:FailedCount++
            return
        }
    } else {
        Write-Log "$($AppInfo.Name) installer already downloaded" -Level INFO
    }

    # Install application
    Write-Log "Installing $($AppInfo.Name)..." -Level INFO

    try {
        $installSuccess = $false

        switch ($AppKey) {
            "Office365" {
                # Create Office configuration XML
                $configXML = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Updates Enabled="TRUE" />
  <RemoveMSI />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
  <Property Name="PinIconsToTaskbar" Value="TRUE" />
</Configuration>
"@
                $configPath = Join-Path $Script:DownloadDir "office365-config.xml"
                $configXML | Out-File -FilePath $configPath -Encoding UTF8

                # Run Office Deployment Tool
                $process = Start-Process -FilePath $filePath -ArgumentList "/quiet /extract:$($Script:DownloadDir)" -Wait -PassThru -NoNewWindow
                Start-Sleep -Seconds 5

                $setupPath = Join-Path $Script:DownloadDir "setup.exe"
                if (Test-Path $setupPath) {
                    Write-Log "Running Office 365 installation (this may take 15-30 minutes)..." -Level INFO
                    $process = Start-Process -FilePath $setupPath -ArgumentList "/configure `"$configPath`"" -Wait -PassThru -NoNewWindow

                    if ($process.ExitCode -eq 0) {
                        $installSuccess = $true
                    }
                }
            }
            "Teams" {
                $arguments = "-s"
                $process = Start-Process -FilePath $filePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    $installSuccess = $true
                }
            }
            "OneDrive" {
                $arguments = "/silent"
                $process = Start-Process -FilePath $filePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    $installSuccess = $true
                }
            }
            "Edge" {
                $arguments = "/quiet /norestart"
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$filePath`" $arguments" -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    $installSuccess = $true
                }
            }
            "CompanyPortal" {
                # Company Portal installation
                $arguments = "/quiet"
                $process = Start-Process -FilePath $filePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    $installSuccess = $true
                }
            }
            "Netskope" {
                # Netskope Client installation (silent install)
                $arguments = "/quiet /norestart"
                $process = Start-Process -FilePath $filePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                    $installSuccess = $true
                    if ($process.ExitCode -eq 3010) {
                        Write-Log "Netskope Client installed - restart required" -Level WARNING
                    }
                }
            }
        }

        if ($installSuccess) {
            Write-Log "$($AppInfo.Name) installed successfully" -Level SUCCESS
            $Script:SuccessCount++
        } else {
            Write-Log "$($AppInfo.Name) installation failed (exit code: $($process.ExitCode))" -Level ERROR
            $Script:FailedCount++
        }

    } catch {
        Write-Log "Error installing $($AppInfo.Name): $_" -Level ERROR
        $Script:FailedCount++
    }
}

# Create desktop shortcuts
function New-M365Shortcuts {
    Write-Header "Creating Desktop Shortcuts"

    $shortcuts = @{
        "Word" = "$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE"
        "Excel" = "$env:ProgramFiles\Microsoft Office\root\Office16\EXCEL.EXE"
        "PowerPoint" = "$env:ProgramFiles\Microsoft Office\root\Office16\POWERPNT.EXE"
        "Outlook" = "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE"
        "Teams" = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
        "OneDrive" = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
        "Edge" = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    }

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shell = New-Object -ComObject WScript.Shell

    foreach ($app in $shortcuts.GetEnumerator()) {
        if (Test-Path $app.Value) {
            try {
                $shortcutPath = "$desktopPath\$($app.Key).lnk"
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $app.Value
                $shortcut.Save()
                Write-Log "Created shortcut: $($app.Key)" -Level SUCCESS
            } catch {
                Write-Log "Failed to create shortcut for $($app.Key): $_" -Level WARNING
            }
        }
    }
}

# Clean up downloads
function Clear-Downloads {
    Write-Header "Cleaning Up"

    try {
        if (Test-Path $Script:DownloadDir) {
            Remove-Item -Path $Script:DownloadDir -Recurse -Force
            Write-Log "Temporary files cleaned up" -Level SUCCESS
        }
    } catch {
        Write-Log "Failed to clean up downloads: $_" -Level WARNING
    }
}

# Main installation function
function Start-M365Installation {
    Write-Header "Microsoft 365 Applications Installer - v$($Script:Version)"
    Write-Log "Company: $($Script:CompanyName)" -Level INFO
    Write-Log "Support: $($Script:ITSupportEmail)" -Level INFO
    Write-Log "" -Level INFO

    # Check administrator privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator!" -Level ERROR
        Write-Log "Right-click PowerShell and select 'Run as Administrator'" -Level ERROR
        exit 1
    }

    # Check disk space (require 10GB)
    $drive = (Get-Item $env:SystemDrive).PSDrive
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)

    Write-Log "Available disk space: $freeSpaceGB GB" -Level INFO

    if ($freeSpaceGB -lt 10) {
        Write-Log "Insufficient disk space. At least 10 GB required." -Level ERROR
        Write-Log "Please free up disk space and try again." -Level ERROR
        exit 1
    }

    # Check internet connectivity
    Write-Log "Checking internet connectivity..." -Level INFO

    try {
        $testConnection = Test-NetConnection -ComputerName "microsoft.com" -InformationLevel Quiet

        if (-not $testConnection) {
            Write-Log "No internet connection detected" -Level ERROR
            Write-Log "Please connect to the internet and try again" -Level ERROR
            exit 1
        }

        Write-Log "Internet connectivity confirmed" -Level SUCCESS
    } catch {
        Write-Log "Failed to check connectivity: $_" -Level WARNING
        Write-Log "Proceeding anyway..." -Level WARNING
    }

    # Install applications
    foreach ($app in $Script:M365Downloads.GetEnumerator()) {
        Install-M365App -AppKey $app.Key -AppInfo $app.Value
    }

    # Create desktop shortcuts
    New-M365Shortcuts

    # Clean up
    Clear-Downloads

    # Installation summary
    Write-Header "Installation Complete"
    Write-Log "" -Level INFO
    Write-Log "Installation Summary:" -Level INFO
    Write-Log "  Total Applications: $Script:TotalApps" -Level INFO
    Write-Log "  Successfully Installed: $Script:SuccessCount" -Level SUCCESS
    Write-Log "  Already Installed/Skipped: $Script:SkippedCount" -Level WARNING
    Write-Log "  Failed: $Script:FailedCount" -Level ERROR
    Write-Log "" -Level INFO
    Write-Log "Log file: $($Script:LogFile)" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "Next Steps:" -Level INFO
    Write-Log "1. Sign in to Microsoft 365 applications:" -Level INFO
    Write-Log "   - Open any Office app (Word, Excel, PowerPoint, Outlook)" -Level INFO
    Write-Log "   - Click 'Sign In' and use your SBS Federal credentials" -Level INFO
    Write-Log "   - Email: your-email@sbsfederal.com" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "2. Configure OneDrive:" -Level INFO
    Write-Log "   - Open OneDrive from Desktop or Start Menu" -Level INFO
    Write-Log "   - Sign in with SBS Federal credentials" -Level INFO
    Write-Log "   - Choose folders to sync" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "3. Set up Microsoft Teams:" -Level INFO
    Write-Log "   - Open Teams from Desktop or Start Menu" -Level INFO
    Write-Log "   - Sign in with SBS Federal credentials" -Level INFO
    Write-Log "   - Configure audio/video settings" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "4. Configure Microsoft Edge:" -Level INFO
    Write-Log "   - Open Edge from Desktop or Start Menu" -Level INFO
    Write-Log "   - Sign in with SBS Federal account (optional)" -Level INFO
    Write-Log "   - Sync favorites, passwords, and settings" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "5. Enroll in Company Portal:" -Level INFO
    Write-Log "   - Open Company Portal" -Level INFO
    Write-Log "   - Sign in with SBS Federal credentials" -Level INFO
    Write-Log "   - Complete device enrollment" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "For support, contact: $($Script:ITSupportEmail)" -Level INFO
    Write-Header "Setup Complete - Press any key to exit"

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Run installation
try {
    Start-M365Installation
} catch {
    Write-Log "Unexpected error: $_" -Level ERROR
    Write-Log "Please contact $($Script:ITSupportEmail) for support" -Level ERROR
    exit 1
}
