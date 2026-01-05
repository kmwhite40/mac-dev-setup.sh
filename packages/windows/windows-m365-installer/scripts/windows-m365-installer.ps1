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
$Script:Version = "1.1.0"
$Script:CompanyName = "SBS Federal"
$Script:ITSupportEmail = "it@sbsfederal.com"
$Script:LogDir = "$env:USERPROFILE\.m365-installer"
$Script:LogFile = "$Script:LogDir\installer.log"
$Script:DownloadDir = "$Script:LogDir\downloads"
$Script:MinWindowsBuild = 17763  # Windows 10 1809 or later
$Script:MinDiskSpaceGB = 15      # Minimum disk space required
$Script:RequiredDotNetVersion = "4.7.2"

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

#===============================================================================
# Prerequisite Check Functions
#===============================================================================

# Check Windows version
function Test-WindowsVersion {
    Write-Log "Checking Windows version..." -Level INFO

    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $buildNumber = [int]$osInfo.BuildNumber
    $osCaption = $osInfo.Caption

    Write-Log "Operating System: $osCaption" -Level INFO
    Write-Log "Build Number: $buildNumber" -Level INFO

    if ($buildNumber -lt $Script:MinWindowsBuild) {
        Write-Log "Windows build $buildNumber is not supported" -Level ERROR
        Write-Log "Minimum required: Windows 10 Build $Script:MinWindowsBuild (version 1809) or later" -Level ERROR
        return $false
    }

    Write-Log "Windows version check passed" -Level SUCCESS
    return $true
}

# Check and configure TLS 1.2
function Set-TLS12 {
    Write-Log "Configuring TLS 1.2 for secure downloads..." -Level INFO

    try {
        # Enable TLS 1.2 for .NET
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Verify TLS 1.2 is enabled in registry (for future sessions)
        $tlsRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
        if (-not (Test-Path $tlsRegPath)) {
            New-Item -Path $tlsRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $tlsRegPath -Name "Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $tlsRegPath -Name "DisabledByDefault" -Value 0 -Type DWord -ErrorAction SilentlyContinue

        Write-Log "TLS 1.2 configured successfully" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Warning: Could not configure TLS 1.2: $_" -Level WARNING
        return $true  # Continue anyway
    }
}

# Check .NET Framework version
function Test-DotNetFramework {
    Write-Log "Checking .NET Framework..." -Level INFO

    try {
        $netRegPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"

        if (Test-Path $netRegPath) {
            $release = (Get-ItemProperty -Path $netRegPath -Name Release -ErrorAction SilentlyContinue).Release

            # .NET Framework version mapping
            $version = switch ($release) {
                { $_ -ge 533320 } { "4.8.1" }
                { $_ -ge 528040 } { "4.8" }
                { $_ -ge 461808 } { "4.7.2" }
                { $_ -ge 461308 } { "4.7.1" }
                { $_ -ge 460798 } { "4.7" }
                { $_ -ge 394802 } { "4.6.2" }
                { $_ -ge 394254 } { "4.6.1" }
                { $_ -ge 393295 } { "4.6" }
                default { "Unknown ($release)" }
            }

            Write-Log ".NET Framework version: $version" -Level INFO

            if ($release -ge 461808) {  # 4.7.2 or later
                Write-Log ".NET Framework check passed" -Level SUCCESS
                return $true
            }
        }

        Write-Log ".NET Framework 4.7.2 or later is required but not found" -Level WARNING
        return $false
    } catch {
        Write-Log "Could not determine .NET Framework version: $_" -Level WARNING
        return $false
    }
}

# Install .NET Framework if missing
function Install-DotNetFramework {
    Write-Log "Installing .NET Framework 4.8..." -Level INFO

    $dotNetUrl = "https://go.microsoft.com/fwlink/?linkid=2088631"  # .NET 4.8 offline installer
    $dotNetPath = Join-Path $Script:DownloadDir "ndp48-x86-x64-allos-enu.exe"

    try {
        # Download .NET Framework
        if (-not (Test-Path $dotNetPath)) {
            $downloadSuccess = Get-M365File -URL $dotNetUrl -FilePath $dotNetPath -AppName ".NET Framework 4.8"
            if (-not $downloadSuccess) {
                Write-Log "Failed to download .NET Framework installer" -Level ERROR
                return $false
            }
        }

        # Install silently
        Write-Log "Installing .NET Framework 4.8 (this may take several minutes)..." -Level INFO
        $process = Start-Process -FilePath $dotNetPath -ArgumentList "/q /norestart" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log ".NET Framework 4.8 installed successfully" -Level SUCCESS
            if ($process.ExitCode -eq 3010) {
                Write-Log "A restart is required to complete .NET Framework installation" -Level WARNING
            }
            return $true
        } else {
            Write-Log ".NET Framework installation failed (exit code: $($process.ExitCode))" -Level ERROR
            return $false
        }
    } catch {
        Write-Log "Error installing .NET Framework: $_" -Level ERROR
        return $false
    }
}

# Check Visual C++ Redistributables
function Test-VCRedist {
    Write-Log "Checking Visual C++ Redistributables..." -Level INFO

    $vcInstalled = $false

    # Check for VC++ 2015-2022 x64
    $vcRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\X64"
    )

    foreach ($path in $vcRegPaths) {
        if (Test-Path $path) {
            $version = (Get-ItemProperty -Path $path -Name Version -ErrorAction SilentlyContinue).Version
            if ($version) {
                Write-Log "Visual C++ Redistributable found: $version" -Level INFO
                $vcInstalled = $true
                break
            }
        }
    }

    # Also check installed programs
    if (-not $vcInstalled) {
        $vcPrograms = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*Visual C++*2015*" -or $_.DisplayName -like "*Visual C++*2019*" -or $_.DisplayName -like "*Visual C++*2022*" }

        if ($vcPrograms) {
            Write-Log "Visual C++ Redistributable found: $($vcPrograms[0].DisplayName)" -Level INFO
            $vcInstalled = $true
        }
    }

    if ($vcInstalled) {
        Write-Log "Visual C++ Redistributable check passed" -Level SUCCESS
        return $true
    }

    Write-Log "Visual C++ Redistributable not found" -Level WARNING
    return $false
}

# Install Visual C++ Redistributables
function Install-VCRedist {
    Write-Log "Installing Visual C++ Redistributable 2015-2022..." -Level INFO

    $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $vcPath = Join-Path $Script:DownloadDir "vc_redist.x64.exe"

    try {
        # Download VC++ Redist
        if (-not (Test-Path $vcPath)) {
            $downloadSuccess = Get-M365File -URL $vcUrl -FilePath $vcPath -AppName "Visual C++ Redistributable"
            if (-not $downloadSuccess) {
                Write-Log "Failed to download Visual C++ Redistributable" -Level ERROR
                return $false
            }
        }

        # Install silently
        Write-Log "Installing Visual C++ Redistributable..." -Level INFO
        $process = Start-Process -FilePath $vcPath -ArgumentList "/quiet /norestart" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "Visual C++ Redistributable installed successfully" -Level SUCCESS
            return $true
        } else {
            Write-Log "Visual C++ Redistributable installation failed (exit code: $($process.ExitCode))" -Level ERROR
            return $false
        }
    } catch {
        Write-Log "Error installing Visual C++ Redistributable: $_" -Level ERROR
        return $false
    }
}

# Check WebView2 Runtime (required for new Teams)
function Test-WebView2 {
    Write-Log "Checking Microsoft Edge WebView2 Runtime..." -Level INFO

    $webView2Paths = @(
        "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
    )

    foreach ($path in $webView2Paths) {
        if (Test-Path $path) {
            $version = (Get-ItemProperty -Path $path -Name pv -ErrorAction SilentlyContinue).pv
            if ($version) {
                Write-Log "WebView2 Runtime found: $version" -Level INFO
                Write-Log "WebView2 check passed" -Level SUCCESS
                return $true
            }
        }
    }

    Write-Log "WebView2 Runtime not found" -Level WARNING
    return $false
}

# Install WebView2 Runtime
function Install-WebView2 {
    Write-Log "Installing Microsoft Edge WebView2 Runtime..." -Level INFO

    $webView2Url = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"  # Evergreen bootstrapper
    $webView2Path = Join-Path $Script:DownloadDir "MicrosoftEdgeWebview2Setup.exe"

    try {
        # Download WebView2
        if (-not (Test-Path $webView2Path)) {
            $downloadSuccess = Get-M365File -URL $webView2Url -FilePath $webView2Path -AppName "WebView2 Runtime"
            if (-not $downloadSuccess) {
                Write-Log "Failed to download WebView2 Runtime" -Level ERROR
                return $false
            }
        }

        # Install silently
        Write-Log "Installing WebView2 Runtime..." -Level INFO
        $process = Start-Process -FilePath $webView2Path -ArgumentList "/silent /install" -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Log "WebView2 Runtime installed successfully" -Level SUCCESS
            return $true
        } else {
            Write-Log "WebView2 Runtime installation failed (exit code: $($process.ExitCode))" -Level ERROR
            return $false
        }
    } catch {
        Write-Log "Error installing WebView2 Runtime: $_" -Level ERROR
        return $false
    }
}

# Check Windows Update service
function Test-WindowsUpdateService {
    Write-Log "Checking Windows Update service..." -Level INFO

    try {
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue

        if ($wuService) {
            Write-Log "Windows Update service status: $($wuService.Status)" -Level INFO

            if ($wuService.Status -ne 'Running') {
                Write-Log "Starting Windows Update service..." -Level INFO
                Start-Service -Name wuauserv -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }

            Write-Log "Windows Update service check passed" -Level SUCCESS
            return $true
        }

        Write-Log "Windows Update service not found" -Level WARNING
        return $false
    } catch {
        Write-Log "Could not check Windows Update service: $_" -Level WARNING
        return $true  # Continue anyway
    }
}

# Check BITS service (required for downloads)
function Test-BITSService {
    Write-Log "Checking Background Intelligent Transfer Service (BITS)..." -Level INFO

    try {
        $bitsService = Get-Service -Name BITS -ErrorAction SilentlyContinue

        if ($bitsService) {
            Write-Log "BITS service status: $($bitsService.Status)" -Level INFO

            if ($bitsService.Status -ne 'Running') {
                Write-Log "Starting BITS service..." -Level INFO
                Start-Service -Name BITS -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }

            Write-Log "BITS service check passed" -Level SUCCESS
            return $true
        }

        Write-Log "BITS service not found - downloads may fail" -Level WARNING
        return $false
    } catch {
        Write-Log "Could not check BITS service: $_" -Level WARNING
        return $true  # Continue anyway
    }
}

# Main prerequisite check function
function Test-AllPrerequisites {
    Write-Header "Checking Prerequisites"

    $allPassed = $true
    $restartRequired = $false

    # 1. Windows version check (critical)
    if (-not (Test-WindowsVersion)) {
        Write-Log "Windows version requirement not met. Installation cannot continue." -Level ERROR
        return @{ Success = $false; RestartRequired = $false }
    }

    # 2. Configure TLS 1.2
    Set-TLS12

    # 3. Check BITS service
    Test-BITSService

    # 4. Check Windows Update service
    Test-WindowsUpdateService

    # 5. Check .NET Framework
    if (-not (Test-DotNetFramework)) {
        Write-Log "Installing required .NET Framework..." -Level INFO
        if (Install-DotNetFramework) {
            $restartRequired = $true
        } else {
            Write-Log ".NET Framework installation failed - some features may not work" -Level WARNING
        }
    }

    # 6. Check Visual C++ Redistributable
    if (-not (Test-VCRedist)) {
        Write-Log "Installing required Visual C++ Redistributable..." -Level INFO
        Install-VCRedist
    }

    # 7. Check WebView2 Runtime (required for new Teams)
    if (-not (Test-WebView2)) {
        Write-Log "Installing required WebView2 Runtime..." -Level INFO
        Install-WebView2
    }

    Write-Log "" -Level INFO
    Write-Log "Prerequisite check complete" -Level SUCCESS

    if ($restartRequired) {
        Write-Log "IMPORTANT: A restart is required before continuing" -Level WARNING
        Write-Log "Please restart your computer and run this installer again" -Level WARNING
    }

    return @{ Success = $allPassed; RestartRequired = $restartRequired }
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

    # Check disk space
    $drive = (Get-Item $env:SystemDrive).PSDrive
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)

    Write-Log "Available disk space: $freeSpaceGB GB" -Level INFO

    if ($freeSpaceGB -lt $Script:MinDiskSpaceGB) {
        Write-Log "Insufficient disk space. At least $Script:MinDiskSpaceGB GB required." -Level ERROR
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

    # Check and install prerequisites
    $prereqResult = Test-AllPrerequisites

    if (-not $prereqResult.Success) {
        Write-Log "Prerequisite check failed. Please resolve the issues and try again." -Level ERROR
        exit 1
    }

    if ($prereqResult.RestartRequired) {
        Write-Log "" -Level INFO
        Write-Log "A system restart is required to complete prerequisite installation." -Level WARNING
        Write-Log "Please restart your computer and run this installer again." -Level WARNING
        Write-Header "Restart Required - Press any key to exit"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }

    Write-Log "" -Level INFO

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
