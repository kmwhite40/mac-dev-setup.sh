#!/bin/bash

#===============================================================================
# COSMOS Deployment Script
# Version: 1.0.0
# Company: SBS Federal
# Contact: it@sbsfederal.com
#
# Description:
#   Automated installer for the COSMOS development environment on macOS.
#   Installs core tools, browsers, dev/devops applications, and configures
#   a weekly automatic update schedule via launchd.
#
# Package Groups:
#   1. Core Apps         — Homebrew, Xcode CLT, browsers, editors, utilities
#   2. Common Dev+DevOps — Cloud CLIs, IDEs, database tools, NVM/Node
#   3. Common DevOps     — Kubernetes, IaC, load testing
#   4. COSMOS Apps       — WebStorm (optional)
#
# Prerequisites (handled automatically by this script):
#   1. Xcode Command Line Tools
#   2. Homebrew Package Manager
#   3. Internet connection
#
# Usage:
#   chmod +x Cosmos_Deployment.sh
#   ./Cosmos_Deployment.sh
#
#===============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="1.0.0"
COMPANY_NAME="SBS Federal"
IT_SUPPORT_EMAIL="it@sbsfederal.com"
LOG_DIR="$HOME/Library/Logs/cosmos-deployment"
LOG_FILE="$LOG_DIR/cosmos-deployment.log"

# Launchd agent configuration
LAUNCHD_LABEL="com.sbsfederal.cosmos-deployment.weekly-update"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/${LAUNCHD_LABEL}.plist"

# Minimum macOS version (10.14 Mojave)
MIN_MACOS_VERSION="10.14"

# NVM configuration
NVM_DIR="$HOME/.nvm"
NODE_VERSION="24"

#===============================================================================
# Logging Functions
#===============================================================================

mkdir -p "$LOG_DIR"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${MAGENTA}[$(date +'%Y-%m-%d %H:%M:%S')] =========================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${MAGENTA}[$(date +'%Y-%m-%d %H:%M:%S')] =========================================${NC}" | tee -a "$LOG_FILE"
}

#===============================================================================
# System Checks
#===============================================================================

# Check if running as root (should not be)
check_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Please do not run this script as root or with sudo"
        log_error "Run as: ./Cosmos_Deployment.sh"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    log "Checking macOS version..."

    local macos_version
    macos_version=$(sw_vers -productVersion)
    local major_version
    major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version
    minor_version=$(echo "$macos_version" | cut -d. -f2)

    log "Detected macOS version: $macos_version"

    # macOS 11+ (Big Sur and later) uses major version 11+
    if [[ "$major_version" -ge 11 ]]; then
        log_success "macOS version $macos_version is supported"
        return 0
    fi

    # For macOS 10.x, check minor version
    if [[ "$major_version" -eq 10 ]] && [[ "$minor_version" -ge 14 ]]; then
        log_success "macOS version $macos_version is supported"
        return 0
    fi

    log_error "macOS version $macos_version is not supported"
    log_error "Minimum required: macOS $MIN_MACOS_VERSION (Mojave)"
    exit 1
}

# Check internet connectivity
check_internet() {
    log "Checking internet connectivity..."

    if ping -c 1 -t 5 github.com &>/dev/null; then
        log_success "Internet connection verified"
        return 0
    elif ping -c 1 -t 5 google.com &>/dev/null; then
        log_success "Internet connection verified"
        return 0
    else
        log_error "No internet connection detected"
        log_error "Please connect to the internet and try again"
        exit 1
    fi
}

# Check available disk space (require at least 20GB)
check_disk_space() {
    log "Checking available disk space..."

    local available_gb
    available_gb=$(df -g / | awk 'NR==2 {print $4}')
    local required_gb=20

    log "Available disk space: ${available_gb}GB"

    if [[ "$available_gb" -lt "$required_gb" ]]; then
        log_error "Insufficient disk space"
        log_error "Required: ${required_gb}GB, Available: ${available_gb}GB"
        log_error "Please free up disk space and try again"
        exit 1
    fi

    log_success "Sufficient disk space available (${available_gb}GB)"
}

#===============================================================================
# Xcode Command Line Tools
#===============================================================================

install_xcode_clt() {
    log_header "Installing Xcode Command Line Tools"

    # Check if Xcode CLT is already installed
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        log "Path: $(xcode-select -p)"
        return 0
    fi

    log "Xcode Command Line Tools not found. Installing..."
    log_warning "A dialog box will appear. Click 'Install' to proceed."

    # Trigger the installation
    xcode-select --install 2>&1 || true

    # Wait for installation to complete
    log "Waiting for Xcode Command Line Tools installation to complete..."
    log_warning "Please complete the installation dialog and wait..."

    # Poll until installed or timeout (10 minutes)
    local timeout=600
    local elapsed=0
    local interval=10

    while ! xcode-select -p &>/dev/null; do
        sleep $interval
        elapsed=$((elapsed + interval))

        if [[ $elapsed -ge $timeout ]]; then
            log_error "Xcode Command Line Tools installation timed out"
            log_error "Please install manually: xcode-select --install"
            exit 1
        fi

        log "Still waiting for Xcode CLT installation... (${elapsed}s elapsed)"
    done

    log_success "Xcode Command Line Tools installed successfully"
    log "Path: $(xcode-select -p)"

    # Accept Xcode license if needed
    if ! sudo xcodebuild -license check &>/dev/null; then
        log "Accepting Xcode license..."
        sudo xcodebuild -license accept 2>/dev/null || true
    fi
}

#===============================================================================
# Rosetta 2 (for Apple Silicon)
#===============================================================================

install_rosetta() {
    # Only needed on Apple Silicon Macs
    if [[ $(uname -m) != 'arm64' ]]; then
        return 0
    fi

    log "Checking Rosetta 2 (required for some Intel apps on Apple Silicon)..."

    # Check if Rosetta is already installed
    if /usr/bin/pgrep -q oahd; then
        log_success "Rosetta 2 is already installed and running"
        return 0
    fi

    # Check if Rosetta binary exists
    if [[ -f "/Library/Apple/usr/share/rosetta/rosetta" ]]; then
        log_success "Rosetta 2 is already installed"
        return 0
    fi

    log "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
    log_success "Rosetta 2 installed successfully"
}

#===============================================================================
# Homebrew Installation
#===============================================================================

install_homebrew() {
    log_header "Setting Up Homebrew Package Manager"

    if command -v brew &>/dev/null; then
        log_success "Homebrew is already installed"
        log "Homebrew version: $(brew --version | head -1)"
        log "Homebrew path: $(which brew)"

        # Make sure Homebrew is in PATH for this session
        eval_brew_shellenv
        return 0
    fi

    log "Homebrew not found. Installing Homebrew..."
    log_warning "You may be prompted for your password"

    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    eval_brew_shellenv

    # Add to shell profile for persistence
    add_brew_to_profile

    # Verify installation
    if command -v brew &>/dev/null; then
        log_success "Homebrew installed successfully"
        log "Homebrew version: $(brew --version | head -1)"
    else
        log_error "Homebrew installation failed"
        log_error "Please install manually and rerun this script"
        exit 1
    fi
}

eval_brew_shellenv() {
    # Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    # Intel Macs
    else
        if [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

add_brew_to_profile() {
    local shell_profile=""
    local brew_shellenv_line=""

    # Determine shell and profile
    if [[ $(uname -m) == 'arm64' ]]; then
        brew_shellenv_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
    else
        brew_shellenv_line='eval "$(/usr/local/bin/brew shellenv)"'
    fi

    # Add to .zprofile (default shell on modern macOS)
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == "/bin/zsh" ]]; then
        shell_profile="$HOME/.zprofile"
    else
        shell_profile="$HOME/.bash_profile"
    fi

    # Check if already added
    if [[ -f "$shell_profile" ]] && grep -q "brew shellenv" "$shell_profile"; then
        log "Homebrew PATH already configured in $shell_profile"
        return 0
    fi

    # Add to profile
    echo "" >> "$shell_profile"
    echo "# Homebrew" >> "$shell_profile"
    echo "$brew_shellenv_line" >> "$shell_profile"

    log_success "Added Homebrew to $shell_profile"
}

verify_homebrew() {
    log "Verifying Homebrew installation..."

    # Update Homebrew
    log "Updating Homebrew..."
    brew update

    # Run brew doctor
    log "Running brew doctor..."
    if brew doctor 2>&1 | grep -q "Your system is ready to brew"; then
        log_success "Homebrew is healthy and ready"
    else
        log_warning "Homebrew doctor found some issues (usually non-critical)"
        brew doctor || true
    fi
}

#===============================================================================
# Application Installation Functions
#===============================================================================

install_cask() {
    local app=$1
    local app_name=${2:-$app}  # Optional display name

    if brew list --cask "$app" &>/dev/null; then
        log_success "$app_name is already installed"
    else
        log "Installing $app_name..."
        if brew install --cask "$app" 2>&1 | tee -a "$LOG_FILE"; then
            log_success "$app_name installed successfully"
        else
            log_error "Failed to install $app_name"
        fi
    fi
}

install_formula() {
    local tool=$1
    local tool_name=${2:-$tool}  # Optional display name

    if brew list "$tool" &>/dev/null; then
        log_success "$tool_name is already installed"
    else
        log "Installing $tool_name..."
        if brew install "$tool" 2>&1 | tee -a "$LOG_FILE"; then
            log_success "$tool_name installed successfully"
        else
            log_error "Failed to install $tool_name"
        fi
    fi
}

#===============================================================================
# Homebrew Update Functions
#===============================================================================

update_homebrew() {
    log_header "Updating Homebrew Packages"

    log "Updating Homebrew..."
    brew update 2>&1 | tee -a "$LOG_FILE"
    log_success "Homebrew updated"

    log "Upgrading installed packages..."
    brew upgrade 2>&1 | tee -a "$LOG_FILE" || log_warning "Some packages failed to upgrade"
    log_success "Homebrew packages upgraded"

    log "Upgrading installed casks..."
    brew upgrade --cask --greedy 2>&1 | tee -a "$LOG_FILE" || log_warning "Some casks failed to upgrade"
    log_success "Homebrew casks upgraded"

    log "Cleaning up old versions..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"
    log_success "Homebrew cleanup complete"
}

#===============================================================================
# NVM / Node.js Configuration
#===============================================================================

install_and_configure_nvm() {
    log_header "Configuring NVM and Node.js"

    # NVM is installed as a formula — it needs shell configuration
    if ! brew list nvm &>/dev/null; then
        log_warning "NVM formula not found — skipping Node.js configuration"
        return 0
    fi

    # Create NVM working directory
    mkdir -p "$NVM_DIR"

    # Determine shell profile
    local shell_profile
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == "/bin/zsh" ]]; then
        shell_profile="$HOME/.zshrc"
    else
        shell_profile="$HOME/.bashrc"
    fi

    # Add NVM initialization to shell profile if not already present
    if ! grep -q 'NVM_DIR' "$shell_profile" 2>/dev/null; then
        log "Adding NVM configuration to $shell_profile ..."
        cat >> "$shell_profile" << 'NVMEOF'

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
NVMEOF
        log_success "NVM shell configuration added to $shell_profile"
    else
        log_success "NVM shell configuration already present in $shell_profile"
    fi

    # Source NVM for this session
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"

    # Install and configure Node.js via NVM
    if command -v nvm &>/dev/null; then
        log "Installing Node.js v${NODE_VERSION} via NVM..."
        nvm install "$NODE_VERSION" 2>&1 | tee -a "$LOG_FILE" || log_warning "Node.js $NODE_VERSION install had warnings"
        nvm use "$NODE_VERSION" 2>&1 | tee -a "$LOG_FILE"
        nvm alias default "$NODE_VERSION" 2>&1 | tee -a "$LOG_FILE"
        log_success "Node.js $(node --version) installed and set as default via NVM"
    else
        log_warning "NVM command not available in this session"
        log "  Run 'source $shell_profile' then:"
        log "    nvm install $NODE_VERSION"
        log "    nvm use $NODE_VERSION"
        log "    nvm alias default $NODE_VERSION"
    fi
}

#===============================================================================
# Post-Installation Configuration
#===============================================================================

configure_python() {
    # python@3.13 is installed as a dependency of awscli — configure it here
    if brew list python@3.13 &>/dev/null; then
        log "Configuring Python 3.13..."
        python3 -m pip install --upgrade pip --quiet 2>/dev/null || true
        log_success "Python configured: $(python3 --version)"
    fi
}

configure_gcloud() {
    if brew list google-cloud-sdk &>/dev/null; then
        log "Configuring Google Cloud SDK..."

        # Source gcloud shell completions
        local shell_profile
        if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == "/bin/zsh" ]]; then
            shell_profile="$HOME/.zshrc"
        else
            shell_profile="$HOME/.bashrc"
        fi

        if ! grep -q 'google-cloud-sdk' "$shell_profile" 2>/dev/null; then
            cat >> "$shell_profile" << 'GCLOUDEOF'

# Google Cloud SDK
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc" 2>/dev/null || true
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc" 2>/dev/null || true
GCLOUDEOF
            log_success "Google Cloud SDK shell integration added to $shell_profile"
        else
            log_success "Google Cloud SDK shell integration already present"
        fi

        log "  To authenticate: gcloud auth login"
        log "  To set project:  gcloud config set project <PROJECT_ID>"
        log "  Note: gcloud requires Python >= 3.10 (provided by Homebrew python@3.13)"
    fi
}

configure_git_lfs() {
    if command -v git-lfs &>/dev/null; then
        log "Configuring Git LFS..."
        git lfs install 2>&1 | tee -a "$LOG_FILE"
        log_success "Git LFS configured"
    fi
}

configure_docker() {
    if [[ -d "/Applications/Docker.app" ]]; then
        log "Docker Desktop is installed"
        log "  Start Docker Desktop from Applications to complete first-time setup"
    fi
}

#===============================================================================
# Weekly Auto-Update via launchd
#===============================================================================

install_weekly_update_agent() {
    log_header "Configuring Weekly Auto-Update Schedule"

    # Create the update script that launchd will call
    local update_script="$LOG_DIR/cosmos-weekly-update.sh"

    cat > "$update_script" << 'UPDATEEOF'
#!/bin/bash
#===============================================================================
# COSMOS Weekly Auto-Update Script
# Runs unattended via launchd — all output goes to log files
#===============================================================================

set -euo pipefail

LOG_DIR="$HOME/Library/Logs/cosmos-deployment"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$LOG_DIR/weekly-update-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== COSMOS Weekly Auto-Update started ==="

# Ensure Homebrew is on PATH
if [[ "$(uname -m)" == "arm64" ]]; then
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    log "ERROR: Homebrew not found. Aborting."
    osascript -e 'display notification "Weekly update failed: Homebrew not found" with title "COSMOS Deployment"' 2>/dev/null || true
    exit 1
fi

EXIT_CODE=0

# Step 1: Update Homebrew metadata
log "Updating Homebrew metadata..."
if brew update >> "$LOG_FILE" 2>&1; then
    log "OK    Homebrew metadata updated."
else
    log "ERROR brew update failed."
    EXIT_CODE=1
fi

# Step 2: Upgrade all formulae
log "Upgrading formulae..."
if brew upgrade >> "$LOG_FILE" 2>&1; then
    log "OK    Formulae upgraded."
else
    log "ERROR Some formulae failed to upgrade."
    EXIT_CODE=1
fi

# Step 3: Upgrade all casks
log "Upgrading casks..."
if brew upgrade --cask --greedy >> "$LOG_FILE" 2>&1; then
    log "OK    Casks upgraded."
else
    log "ERROR Some casks failed to upgrade."
    EXIT_CODE=1
fi

# Step 4: Cleanup
log "Cleaning up old versions..."
brew cleanup >> "$LOG_FILE" 2>&1 || true
log "OK    Cleanup done."

# Step 5: Prune old log files (keep last 60 days)
find "$LOG_DIR" -name "weekly-update-*.log" -mtime +60 -delete 2>/dev/null || true

# Notify user
if [[ $EXIT_CODE -eq 0 ]]; then
    log "OK    Weekly update completed successfully."
    osascript -e 'display notification "All packages are up to date." with title "COSMOS Deployment"' 2>/dev/null || true
else
    log "ERROR Weekly update completed with errors. Check: $LOG_FILE"
    osascript -e "display notification \"Update finished with errors. Check logs.\" with title \"COSMOS Deployment\"" 2>/dev/null || true
fi

exit $EXIT_CODE
UPDATEEOF

    chmod +x "$update_script"
    log_success "Update script created: $update_script"

    # Unload existing agent if present
    if launchctl list "$LAUNCHD_LABEL" &>/dev/null; then
        log "Unloading existing launchd agent..."
        launchctl bootout "gui/$(id -u)/$LAUNCHD_LABEL" 2>/dev/null || \
            launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
        log_success "Existing agent unloaded"
    fi

    # Create the launchd plist
    mkdir -p "$HOME/Library/LaunchAgents"

    cat > "$LAUNCHD_PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LAUNCHD_LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${update_script}</string>
    </array>

    <!-- Run weekly: every Sunday at 10:00 AM -->
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/launchd-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/launchd-stderr.log</string>

    <!-- Do not run at load, only on schedule -->
    <key>RunAtLoad</key>
    <false/>

    <!-- Low priority so it doesn't interfere with user work -->
    <key>Nice</key>
    <integer>10</integer>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
PLISTEOF

    log_success "Launchd plist created: $LAUNCHD_PLIST"

    # Load the agent
    log "Loading launchd agent..."
    if launchctl bootstrap "gui/$(id -u)" "$LAUNCHD_PLIST" 2>/dev/null || \
       launchctl load "$LAUNCHD_PLIST" 2>/dev/null; then
        log_success "Weekly update agent loaded: $LAUNCHD_LABEL"
    else
        log_error "Failed to load launchd agent"
        log "  Debug: launchctl list | grep cosmos"
    fi

    # Verify
    if launchctl list "$LAUNCHD_LABEL" &>/dev/null; then
        log_success "Weekly auto-update agent is active"
    else
        log "Agent registered — it will appear after its first scheduled run (Sunday 10:00 AM)"
    fi

    log "Schedule: Every Sunday at 10:00 AM"
    log "Logs:     $LOG_DIR/weekly-update-*.log"
    log ""
    log "To disable: launchctl bootout gui/$(id -u)/$LAUNCHD_LABEL"
    log "To re-enable: launchctl bootstrap gui/$(id -u) $LAUNCHD_PLIST"
    log "To run now:   bash $update_script"
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    # Clear screen and show banner
    clear
    echo ""
    log_header "COSMOS Deployment v${SCRIPT_VERSION}"
    log "Company: $COMPANY_NAME"
    log "Support: $IT_SUPPORT_EMAIL"
    log "Log file: $LOG_FILE"
    echo ""

    # -----------------------------------------------------------------------
    # System Prerequisites
    # -----------------------------------------------------------------------
    log_header "System Prerequisites Check"
    check_not_root
    check_macos_version
    check_internet
    check_disk_space

    # Install Xcode Command Line Tools (required for Homebrew and git)
    install_xcode_clt

    # Install Rosetta 2 (Apple Silicon only)
    install_rosetta

    # Install and verify Homebrew
    install_homebrew
    verify_homebrew

    # Update existing packages before installing new ones
    update_homebrew

    # ===================================================================
    # GROUP 1: Core Apps
    # ===================================================================
    log_header "Installing Core Apps"

    # --- Browsers ---
    install_cask "google-chrome" "Google Chrome"
    install_cask "microsoft-edge" "Microsoft Edge"
    install_cask "brave-browser" "Brave Browser"
    install_cask "firefox" "Firefox"
    # NOTE: DuckDuckGo does not have an official Homebrew cask for macOS.
    # Install manually from: https://duckduckgo.com/mac
    log_warning "DuckDuckGo Browser: No Homebrew cask available"
    log "  Install manually from: https://duckduckgo.com/mac"

    # --- Containers ---
    install_cask "docker" "Docker Desktop"
    install_cask "podman-desktop" "Podman Desktop"

    # --- Editors & Terminals ---
    install_cask "obsidian" "Obsidian"
    install_cask "sublime-text" "Sublime Text"
    install_cask "iterm2" "iTerm2"

    # --- CLI Utilities ---
    install_formula "git" "Git"
    install_formula "git-lfs" "Git LFS"
    install_formula "curl" "cURL"
    install_formula "httpie" "HTTPie"
    install_formula "python@3.13" "Python 3.13"
    # NOTE: python@3.14 is not yet available in Homebrew stable.
    # When released, change the line above to: install_formula "python@3.14" "Python 3.14"
    install_formula "dotnet" ".NET SDK"
    install_formula "openssl@3" "OpenSSL 3"
    install_formula "jq" "jq (JSON processor)"

    # --- Diagramming ---
    install_cask "drawio" "draw.io"

    # --- Other ---
    install_formula "coder" "Coder"

    # ===================================================================
    # GROUP 2: Common Dev + DevOps Apps
    # ===================================================================
    log_header "Installing Common Dev + DevOps Apps"

    install_formula "awscli" "AWS CLI"
    install_formula "azure-cli" "Azure CLI"

    install_cask "visual-studio-code" "Visual Studio Code"
    install_cask "postman" "Postman"
    install_cask "dbeaver-community" "DBeaver Community"
    install_cask "tableplus" "TablePlus"

    # NVM (Node Version Manager) — NOT node directly
    install_formula "nvm" "NVM (Node Version Manager)"

    # ===================================================================
    # GROUP 3: Common DevOps Apps
    # ===================================================================
    log_header "Installing Common DevOps Apps"

    install_cask "google-cloud-sdk" "Google Cloud SDK"
    install_formula "kubernetes-cli" "kubectl"
    install_formula "helm" "Helm"
    install_formula "k9s" "K9s"
    install_formula "k6" "k6 Load Testing"
    install_formula "terraform" "Terraform"
    install_formula "ansible" "Ansible"

    # ===================================================================
    # GROUP 4: COSMOS Apps
    # ===================================================================
    log_header "Installing COSMOS Apps"

    # WebStorm — install if not already present, can be skipped if not needed
    install_cask "webstorm" "WebStorm"

    # ===================================================================
    # Post-Installation Configuration
    # ===================================================================
    log_header "Post-Installation Configuration"

    configure_git_lfs
    configure_python
    install_and_configure_nvm
    configure_gcloud
    configure_docker

    # ===================================================================
    # Weekly Auto-Update via launchd
    # ===================================================================
    install_weekly_update_agent

    # ===================================================================
    # Final Cleanup
    # ===================================================================
    log_header "Final Cleanup"

    log "Running Homebrew cleanup..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"

    log "Running Homebrew doctor..."
    brew doctor 2>&1 | tee -a "$LOG_FILE" || log_warning "Homebrew doctor found some issues (usually non-critical)"

    # ===================================================================
    # Completion Summary
    # ===================================================================
    log_header "COSMOS Deployment Complete!"
    log_success "All packages have been installed"
    log ""
    log "Log file: $LOG_FILE"
    log "Weekly update logs: $LOG_DIR/weekly-update-*.log"
    log "Weekly update schedule: Every Sunday at 10:00 AM"
    log ""

    log_header "Next Steps"
    log "1. DuckDuckGo Browser: Install from https://duckduckgo.com/mac"
    log "2. Docker:  Start Docker Desktop from Applications"
    log "3. Git:     Configure your identity:"
    log "     git config --global user.name 'Your Name'"
    log "     git config --global user.email 'you@${COMPANY_NAME// /}.com'"
    log "4. AWS CLI: Run 'aws configure' to set up credentials"
    log "5. Azure:   Run 'az login' to authenticate"
    log "6. GCloud:  Run 'gcloud auth login' to authenticate"
    log "7. NVM:     Open a new terminal, then:"
    log "     nvm install $NODE_VERSION"
    log "     nvm use $NODE_VERSION"
    log "     nvm alias default $NODE_VERSION"
    log "8. Manage auto-updates:"
    log "     Disable: launchctl bootout gui/$(id -u)/$LAUNCHD_LABEL"
    log "     Enable:  launchctl bootstrap gui/$(id -u) $LAUNCHD_PLIST"
    log "     Run now: bash $LOG_DIR/cosmos-weekly-update.sh"
    log ""
    log "For support, contact: $IT_SUPPORT_EMAIL"
    log_header "Setup Complete"
}

# Run main function
main "$@"
