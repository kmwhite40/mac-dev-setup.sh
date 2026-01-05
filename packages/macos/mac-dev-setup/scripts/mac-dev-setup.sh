#!/bin/bash

#===============================================================================
# Mac Development Environment Setup Script
# Version: 2.1.0
# Company: SBS Federal
# Contact: it@sbsfederal.com
#
# Description:
#   Automated installer for development tools and applications on macOS.
#   Includes automatic Xcode CLT installation, Homebrew setup, and
#   forced system updates every 4 days.
#
# Prerequisites (handled automatically by this script):
#   1. Xcode Command Line Tools
#   2. Homebrew Package Manager
#   3. Internet connection
#
# Usage:
#   chmod +x mac-dev-setup.sh
#   ./mac-dev-setup.sh
#
#===============================================================================

# Exit on error, but allow individual commands to fail gracefully
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.1.0"
COMPANY_NAME="SBS Federal"
IT_SUPPORT_EMAIL="it@sbsfederal.com"
UPDATE_MARKER_FILE="$HOME/.mac-dev-setup-last-update"
UPDATE_INTERVAL_DAYS=4
LOG_FILE="$HOME/.mac-dev-setup.log"

# Minimum macOS version (10.14 Mojave)
MIN_MACOS_VERSION="10.14"

#===============================================================================
# Logging Functions
#===============================================================================

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
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root or with sudo"
        log_error "Run as: ./mac-dev-setup.sh"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    log "Checking macOS version..."

    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)

    log "Detected macOS version: $macos_version"

    # macOS 11+ (Big Sur and later) uses major version 11+
    if [ "$major_version" -ge 11 ]; then
        log_success "macOS version $macos_version is supported"
        return 0
    fi

    # For macOS 10.x, check minor version
    if [ "$major_version" -eq 10 ] && [ "$minor_version" -ge 14 ]; then
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

    if ping -c 1 -t 5 github.com &> /dev/null; then
        log_success "Internet connection verified"
        return 0
    elif ping -c 1 -t 5 google.com &> /dev/null; then
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

    local available_gb=$(df -g / | awk 'NR==2 {print $4}')
    local required_gb=20

    log "Available disk space: ${available_gb}GB"

    if [ "$available_gb" -lt "$required_gb" ]; then
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
    if xcode-select -p &> /dev/null; then
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

    while ! xcode-select -p &> /dev/null; do
        sleep $interval
        elapsed=$((elapsed + interval))

        if [ $elapsed -ge $timeout ]; then
            log_error "Xcode Command Line Tools installation timed out"
            log_error "Please install manually: xcode-select --install"
            exit 1
        fi

        log "Still waiting for Xcode CLT installation... (${elapsed}s elapsed)"
    done

    log_success "Xcode Command Line Tools installed successfully"
    log "Path: $(xcode-select -p)"

    # Accept Xcode license if needed
    if ! sudo xcodebuild -license check &> /dev/null; then
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
    if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
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

    if command -v brew &> /dev/null; then
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
    if command -v brew &> /dev/null; then
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
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    # Intel Macs
    else
        if [ -f "/usr/local/bin/brew" ]; then
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
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
        shell_profile="$HOME/.zprofile"
    else
        shell_profile="$HOME/.bash_profile"
    fi

    # Check if already added
    if [ -f "$shell_profile" ] && grep -q "brew shellenv" "$shell_profile"; then
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
# System Update Functions
#===============================================================================

should_update_system() {
    if [ ! -f "$UPDATE_MARKER_FILE" ]; then
        return 0  # No marker file, should update
    fi

    local last_update=$(cat "$UPDATE_MARKER_FILE")
    local current_time=$(date +%s)
    local time_diff=$(( (current_time - last_update) / 86400 ))  # Convert to days

    if [ $time_diff -ge $UPDATE_INTERVAL_DAYS ]; then
        return 0  # Time to update
    else
        log_warning "Last system update was $time_diff days ago (updating every $UPDATE_INTERVAL_DAYS days)"
        return 1  # Not time yet
    fi
}

mark_update_complete() {
    date +%s > "$UPDATE_MARKER_FILE"
    log_success "Update timestamp recorded"
}

update_macos_system() {
    log_header "Checking macOS System Updates"

    # Check for available updates
    log "Scanning for available updates..."
    local updates_available=$(softwareupdate -l 2>&1)

    if echo "$updates_available" | grep -q "No new software available"; then
        log_success "macOS is up to date"
    else
        log "Updates available:"
        echo "$updates_available" | grep -E "^\s+\*" | tee -a "$LOG_FILE"

        log "Installing macOS system updates (this may take a while)..."
        log_warning "You may be prompted for your password"

        sudo softwareupdate -ia --verbose 2>&1 | tee -a "$LOG_FILE"
        log_success "macOS system updates installed"

        # Check if restart is required
        if echo "$updates_available" | grep -qi "restart"; then
            log_warning "A system restart is recommended to complete updates"
            echo ""
            read -p "Do you want to restart now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Restarting system in 60 seconds... (Press Ctrl+C to cancel)"
                sudo shutdown -r +1
                exit 0
            fi
        fi
    fi
}

update_homebrew() {
    log_header "Updating Homebrew Packages"

    log "Updating Homebrew..."
    brew update 2>&1 | tee -a "$LOG_FILE"
    log_success "Homebrew updated"

    log "Upgrading installed packages..."
    brew upgrade 2>&1 | tee -a "$LOG_FILE" || log_warning "Some packages failed to upgrade"
    log_success "Homebrew packages upgraded"

    log "Cleaning up old versions..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"
    log_success "Homebrew cleanup complete"
}

#===============================================================================
# Application Installation Functions
#===============================================================================

install_cask() {
    local app=$1
    local app_name=${2:-$app}  # Optional display name

    if brew list --cask "$app" &> /dev/null; then
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

    if brew list "$tool" &> /dev/null; then
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
# Desktop Shortcuts
#===============================================================================

create_desktop_shortcut() {
    local app_name="$1"
    local app_path="$2"
    local desktop_path="$HOME/Desktop"
    local shortcut_path="$desktop_path/$app_name"

    if [ -d "$app_path" ]; then
        if [ ! -L "$shortcut_path" ] && [ ! -e "$shortcut_path" ]; then
            ln -s "$app_path" "$shortcut_path"
            log_success "Created desktop shortcut for $app_name"
        else
            log_success "Desktop shortcut for $app_name already exists"
        fi
    else
        log_warning "$app_name not found at $app_path, skipping shortcut"
    fi
}

create_desktop_shortcuts() {
    log_header "Creating Desktop Shortcuts"

    local desktop_path="$HOME/Desktop"

    # Ensure Desktop exists
    if [ ! -d "$desktop_path" ]; then
        log_warning "Desktop folder not found, skipping shortcuts"
        return 0
    fi

    # Create shortcuts for each application
    create_desktop_shortcut "Cursor" "/Applications/Cursor.app"
    create_desktop_shortcut "Visual Studio Code" "/Applications/Visual Studio Code.app"
    create_desktop_shortcut "iTerm" "/Applications/iTerm.app"
    create_desktop_shortcut "Docker" "/Applications/Docker.app"
    create_desktop_shortcut "Podman Desktop" "/Applications/Podman Desktop.app"
    create_desktop_shortcut "Postman" "/Applications/Postman.app"
    create_desktop_shortcut "GitHub Desktop" "/Applications/GitHub Desktop.app"
    create_desktop_shortcut "IntelliJ IDEA CE" "/Applications/IntelliJ IDEA CE.app"
    create_desktop_shortcut "Obsidian" "/Applications/Obsidian.app"
    create_desktop_shortcut "DBeaver" "/Applications/DBeaver.app"
    create_desktop_shortcut "MongoDB Compass" "/Applications/MongoDB Compass.app"
}

#===============================================================================
# Post-Installation Configuration
#===============================================================================

configure_java() {
    if brew list openjdk &> /dev/null; then
        log "Configuring Java (OpenJDK)..."

        # Create symlink for system Java wrappers
        local jdk_path=$(brew --prefix openjdk)/libexec/openjdk.jdk
        if [ -d "$jdk_path" ]; then
            sudo ln -sfn "$jdk_path" /Library/Java/JavaVirtualMachines/openjdk.jdk 2>/dev/null || true
            log_success "Java configured: $(java -version 2>&1 | head -1)"
        fi
    fi
}

configure_python() {
    if brew list python &> /dev/null; then
        log "Configuring Python..."

        # Ensure pip is up to date
        python3 -m pip install --upgrade pip --quiet 2>/dev/null || true
        log_success "Python configured: $(python3 --version)"
    fi
}

configure_node() {
    if brew list node &> /dev/null; then
        log "Configuring Node.js..."

        # Update npm
        npm install -g npm@latest --quiet 2>/dev/null || true
        log_success "Node.js configured: $(node --version)"
    fi
}

configure_github_cli() {
    if command -v gh &> /dev/null; then
        log "GitHub CLI (gh) is installed"
        log "  To authenticate: gh auth login"
        log "  To setup git credentials: gh auth setup-git"
    fi
}

configure_gitlab_cli() {
    if command -v glab &> /dev/null; then
        log "GitLab CLI (glab) is installed"
        log "  To authenticate: glab auth login"
    fi
}

configure_docker() {
    if [ -d "/Applications/Docker.app" ]; then
        log "Docker Desktop is installed"
        log "  Start Docker Desktop from Applications or Desktop shortcut"
        log "  First launch may require additional setup"
    fi
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    # Clear screen and show banner
    clear
    echo ""
    log_header "Mac Development Environment Setup v${SCRIPT_VERSION}"
    log "Company: $COMPANY_NAME"
    log "Support: $IT_SUPPORT_EMAIL"
    log "Log file: $LOG_FILE"
    echo ""

    # System checks
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

    # System updates (every 4 days)
    if should_update_system; then
        log_warning "Forced system update required (last update was more than $UPDATE_INTERVAL_DAYS days ago)"
        update_macos_system
        update_homebrew
        mark_update_complete
    else
        update_homebrew
    fi

    # --- GUI Applications ---
    log_header "Installing GUI Applications"

    # Containers
    install_cask "docker" "Docker Desktop"
    install_cask "podman-desktop" "Podman Desktop"

    # Terminals & Editors
    install_cask "iterm2" "iTerm2"
    install_cask "visual-studio-code" "Visual Studio Code"
    install_cask "cursor" "Cursor AI Editor"
    install_cask "intellij-idea-ce" "IntelliJ IDEA Community"

    # Productivity
    install_cask "obsidian" "Obsidian"

    # API & Database Tools
    install_cask "postman" "Postman"
    install_cask "pgadmin4" "pgAdmin 4"
    install_cask "tableplus" "TablePlus"
    install_cask "dbeaver-community" "DBeaver Community"
    install_cask "mongodb-compass" "MongoDB Compass"

    # Git Clients
    install_cask "github" "GitHub Desktop"
    # Note: GitLab doesn't have an official desktop app cask
    # Use glab CLI for GitLab operations

    # --- CLI Tools ---
    log_header "Installing CLI Tools"

    # Version Control
    install_formula "git" "Git"
    install_formula "gh" "GitHub CLI"
    install_formula "glab" "GitLab CLI"

    # Build Tools
    install_formula "maven" "Apache Maven"

    # Programming Languages
    install_formula "node" "Node.js"
    install_formula "python" "Python 3"
    install_formula "openjdk" "OpenJDK"
    install_formula "go" "Go"
    install_formula "dotnet" ".NET SDK"

    # Kubernetes & Cloud
    install_formula "kubectl" "kubectl"
    install_formula "helm" "Helm"
    install_formula "k9s" "K9s"

    # Cloud CLIs
    install_formula "awscli" "AWS CLI"
    install_formula "azure-cli" "Azure CLI"
    install_formula "google-cloud-sdk" "Google Cloud SDK"

    # Infrastructure as Code
    install_formula "terraform" "Terraform"
    install_formula "ansible" "Ansible"

    # HTTP & Testing Tools
    install_formula "curl" "cURL"
    install_formula "httpie" "HTTPie"
    install_formula "k6" "k6 Load Testing"
    install_formula "jq" "jq (JSON processor)"

    # Development Tools
    install_formula "coder" "Coder"

    # --- Post-Installation Configuration ---
    log_header "Post-Installation Configuration"
    configure_java
    configure_python
    configure_node

    # Create desktop shortcuts
    create_desktop_shortcuts

    # --- Final Cleanup ---
    log_header "Final Cleanup"
    log "Running Homebrew cleanup..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"

    log "Running Homebrew doctor..."
    brew doctor 2>&1 | tee -a "$LOG_FILE" || log_warning "Homebrew doctor found some issues (usually non-critical)"

    # --- Completion Summary ---
    log_header "Installation Complete!"
    log_success "All development tools have been installed"
    log ""
    log "Log file: $LOG_FILE"
    log "Next forced system update: $(date -v+${UPDATE_INTERVAL_DAYS}d '+%Y-%m-%d')"
    log ""

    log_header "Next Steps"
    log "1. GitHub CLI: Run 'gh auth login' to authenticate"
    log "2. GitLab CLI: Run 'glab auth login' to authenticate"
    log "3. Docker: Start Docker Desktop from Applications"
    log "4. Git: Configure your identity:"
    log "     git config --global user.name 'Your Name'"
    log "     git config --global user.email 'you@$COMPANY_NAME.com'"
    log "5. Check Desktop for application shortcuts"
    log ""
    log "For support, contact: $IT_SUPPORT_EMAIL"
    log_header "Setup Complete"
}

# Run main function
main "$@"
