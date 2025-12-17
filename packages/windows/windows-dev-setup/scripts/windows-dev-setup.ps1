<#
.SYNOPSIS
    Windows Developer Environment Setup Script

.DESCRIPTION
    Automated installer for development tools and applications on Windows endpoints.
    Designed for SBS Federal - Enterprise-grade deployment with comprehensive logging.

.NOTES
    Version: 2.0.0
    Company: SBS Federal
    Author: IT Department
    Contact: it@sbsfederal.com

.FEATURES
    - Automatic Chocolatey installation
    - Forced Windows Updates every 4 days
    - Smart installation checks
    - Desktop shortcuts creation
    - Comprehensive logging
    - Individual error handling
    - GitHub/GitLab integration
    - Cursor AI editor support
#>

#Requires -RunAsAdministrator

# Script configuration
$Script:Version = "2.0.0"
$Script:CompanyName = "SBS Federal"
$Script:ITSupportEmail = "it@sbsfederal.com"
$Script:UpdateIntervalDays = 4
$Script:LogDir = "$env:USERPROFILE\.windows-dev-setup"
$Script:LogFile = "$LogDir\setup.log"
$Script:UpdateMarkerFile = "$LogDir\.last-update"

# Statistics
$Script:TotalApps = 0
$Script:SuccessCount = 0
$Script:SkippedCount = 0
$Script:FailedCount = 0

# Create log directory
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
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

    # Console output with colors
    switch ($Level) {
        'INFO'    { Write-Host $logMessage -ForegroundColor Cyan }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
    }

    # File output
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-Header {
    param([string]$Text)

    $separator = "=" * 60
    Write-Log $separator -Level INFO
    Write-Log $Text -Level INFO
    Write-Log $separator -Level INFO
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if update is needed
function Test-UpdateNeeded {
    if (-not (Test-Path $UpdateMarkerFile)) {
        return $true
    }

    $lastUpdate = [int64](Get-Content $UpdateMarkerFile)
    $currentTime = [int64](Get-Date -UFormat %s)
    $daysSinceUpdate = [math]::Floor(($currentTime - $lastUpdate) / 86400)

    return ($daysSinceUpdate -ge $UpdateIntervalDays)
}

# Update marker file
function Update-MarkerFile {
    $currentTime = [int64](Get-Date -UFormat %s)
    $currentTime | Out-File -FilePath $UpdateMarkerFile -Force
}

# Check for Windows Updates
function Install-WindowsUpdates {
    Write-Header "Checking for Windows Updates"

    try {
        # Install PSWindowsUpdate module if not present
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Log "Installing PSWindowsUpdate module..." -Level INFO
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
        }

        Import-Module PSWindowsUpdate

        Write-Log "Downloading and installing Windows Updates..." -Level INFO
        Write-Log "This may take 10-30 minutes..." -Level WARNING

        Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false -Verbose | Out-File -FilePath "$LogDir\windows-updates.log"

        Write-Log "Windows Updates completed" -Level SUCCESS
        Update-MarkerFile

    } catch {
        Write-Log "Failed to install Windows Updates: $_" -Level ERROR
        Write-Log "Continuing with application installation..." -Level WARNING
    }
}

# Install Chocolatey
function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Log "Chocolatey already installed" -Level SUCCESS
        return
    }

    Write-Log "Installing Chocolatey package manager..." -Level INFO

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "Chocolatey installed successfully" -Level SUCCESS
    } catch {
        Write-Log "Failed to install Chocolatey: $_" -Level ERROR
        exit 1
    }
}

# Check if application is installed
function Test-AppInstalled {
    param([string]$AppName)

    $chocoList = choco list --local-only | Select-String -Pattern "^$AppName "

    if ($chocoList) {
        return $true
    }

    # Check common installation paths
    $programFiles = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        "$env:LOCALAPPDATA\Programs"
    )

    foreach ($path in $programFiles) {
        if (Test-Path "$path\$AppName") {
            return $true
        }
    }

    return $false
}

# Install application via Chocolatey
function Install-ChocoApp {
    param(
        [string]$PackageName,
        [string]$DisplayName
    )

    $Script:TotalApps++

    Write-Header "Installing $DisplayName"

    # Check if already installed
    if (Test-AppInstalled $PackageName) {
        Write-Log "$DisplayName is already installed - skipping" -Level WARNING
        $Script:SkippedCount++
        return
    }

    Write-Log "Installing $DisplayName..." -Level INFO

    try {
        $result = choco install $PackageName -y --no-progress 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$DisplayName installed successfully" -Level SUCCESS
            $Script:SuccessCount++
        } else {
            Write-Log "$DisplayName installation failed" -Level ERROR
            $Script:FailedCount++
        }
    } catch {
        Write-Log "Error installing $DisplayName: $_" -Level ERROR
        $Script:FailedCount++
    }
}

# Create desktop shortcut
function New-DesktopShortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutName
    )

    if (-not (Test-Path $TargetPath)) {
        return
    }

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\$ShortcutName.lnk"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Save()

    Write-Log "Created desktop shortcut: $ShortcutName" -Level SUCCESS
}

# Main installation function
function Start-Installation {
    Write-Header "Windows Developer Environment Setup - v$Version"
    Write-Log "Company: $CompanyName" -Level INFO
    Write-Log "Support: $ITSupportEmail" -Level INFO
    Write-Log "" -Level INFO

    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Log "This script must be run as Administrator!" -Level ERROR
        Write-Log "Right-click PowerShell and select 'Run as Administrator'" -Level ERROR
        exit 1
    }

    # Check for Windows Updates
    if (Test-UpdateNeeded) {
        Write-Log "System update check required (every $UpdateIntervalDays days)" -Level INFO
        Install-WindowsUpdates
    } else {
        Write-Log "System updates checked recently - skipping" -Level INFO
    }

    # Install Chocolatey
    Write-Header "Setting Up Package Manager"
    Install-Chocolatey

    # Development Tools
    Write-Header "Installing Development Tools"
    Install-ChocoApp "git" "Git"
    Install-ChocoApp "gh" "GitHub CLI"
    Install-ChocoApp "github-desktop" "GitHub Desktop"
    Install-ChocoApp "gitlab-runner" "GitLab Runner"

    # Programming Languages
    Write-Header "Installing Programming Languages"
    Install-ChocoApp "python" "Python"
    Install-ChocoApp "nodejs" "Node.js"
    Install-ChocoApp "openjdk" "OpenJDK"
    Install-ChocoApp "golang" "Go"
    Install-ChocoApp "dotnet-sdk" ".NET SDK"

    # Build Tools
    Write-Header "Installing Build Tools"
    Install-ChocoApp "maven" "Apache Maven"
    Install-ChocoApp "gradle" "Gradle"

    # IDEs and Editors
    Write-Header "Installing IDEs and Editors"
    Install-ChocoApp "vscode" "Visual Studio Code"
    Install-ChocoApp "intellijidea-community" "IntelliJ IDEA Community"

    # Note: Cursor is not in Chocolatey, download manually
    Write-Log "Note: Cursor AI Editor must be downloaded from https://cursor.sh" -Level WARNING

    # Containers
    Write-Header "Installing Container Tools"
    Install-ChocoApp "docker-desktop" "Docker Desktop"

    # Terminals
    Write-Header "Installing Terminal Emulators"
    Install-ChocoApp "microsoft-windows-terminal" "Windows Terminal"

    # Cloud CLI Tools
    Write-Header "Installing Cloud CLI Tools"
    Install-ChocoApp "awscli" "AWS CLI"
    Install-ChocoApp "azure-cli" "Azure CLI"
    Install-ChocoApp "gcloudsdk" "Google Cloud SDK"

    # Kubernetes Tools
    Write-Header "Installing Kubernetes Tools"
    Install-ChocoApp "kubernetes-cli" "kubectl"
    Install-ChocoApp "kubernetes-helm" "Helm"
    Install-ChocoApp "k9s" "K9s"

    # Infrastructure as Code
    Write-Header "Installing IaC Tools"
    Install-ChocoApp "terraform" "Terraform"
    Install-ChocoApp "ansible" "Ansible"

    # Productivity Tools
    Write-Header "Installing Productivity Tools"
    Install-ChocoApp "obsidian" "Obsidian"
    Install-ChocoApp "notion" "Notion"

    # API Development
    Write-Header "Installing API Development Tools"
    Install-ChocoApp "postman" "Postman"
    Install-ChocoApp "insomnia-rest-api-client" "Insomnia"

    # Database Tools
    Write-Header "Installing Database Tools"
    Install-ChocoApp "dbeaver" "DBeaver"
    Install-ChocoApp "tableplus" "TablePlus"
    Install-ChocoApp "mongodb-compass" "MongoDB Compass"

    # HTTP/Performance Testing
    Write-Header "Installing Testing Tools"
    Install-ChocoApp "curl" "cURL"
    Install-ChocoApp "wget" "wget"
    Install-ChocoApp "jq" "jq"

    # Create desktop shortcuts
    Write-Header "Creating Desktop Shortcuts"
    New-DesktopShortcut "$env:ProgramFiles\Git\git-bash.exe" "Git Bash"
    New-DesktopShortcut "$env:ProgramFiles\Microsoft VS Code\Code.exe" "Visual Studio Code"
    New-DesktopShortcut "$env:ProgramFiles\JetBrains\IntelliJ IDEA Community Edition\bin\idea64.exe" "IntelliJ IDEA"
    New-DesktopShortcut "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe" "Docker Desktop"
    New-DesktopShortcut "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe" "Windows Terminal"
    New-DesktopShortcut "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe" "GitHub Desktop"
    New-DesktopShortcut "$env:LOCALAPPDATA\Postman\Postman.exe" "Postman"

    # Installation summary
    Write-Header "Installation Complete"
    Write-Log "" -Level INFO
    Write-Log "Installation Summary:" -Level INFO
    Write-Log "  Total Applications: $TotalApps" -Level INFO
    Write-Log "  Successfully Installed: $SuccessCount" -Level SUCCESS
    Write-Log "  Already Installed/Skipped: $SkippedCount" -Level WARNING
    Write-Log "  Failed: $FailedCount" -Level ERROR
    Write-Log "" -Level INFO
    Write-Log "Log file: $LogFile" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "Next Steps:" -Level INFO
    Write-Log "1. Restart your computer to complete installation" -Level INFO
    Write-Log "2. Configure Git with your credentials:" -Level INFO
    Write-Log "   git config --global user.name 'Your Name'" -Level INFO
    Write-Log "   git config --global user.email 'you@sbsfederal.com'" -Level INFO
    Write-Log "3. Sign in to GitHub Desktop with your SBS Federal account" -Level INFO
    Write-Log "4. Download Cursor AI from https://cursor.sh" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "For support, contact: $ITSupportEmail" -Level INFO
    Write-Header "Setup Complete - Press any key to exit"

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Run installation
try {
    Start-Installation
} catch {
    Write-Log "Unexpected error: $_" -Level ERROR
    Write-Log "Please contact $ITSupportEmail for support" -Level ERROR
    exit 1
}
