#!/bin/bash

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UPDATE_MARKER_FILE="$HOME/.mac-dev-setup-last-update"
UPDATE_INTERVAL_DAYS=4
LOG_FILE="$HOME/.mac-dev-setup.log"

# Logging function
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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root or with sudo"
    exit 1
fi

# Function to check if system update is needed (every 4 days)
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

# Function to mark update as done
mark_update_complete() {
    date +%s > "$UPDATE_MARKER_FILE"
    log_success "Update timestamp recorded"
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == 'arm64' ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        log_success "Homebrew installed successfully"
    else
        log_success "Homebrew is already installed"
    fi
}

# Function to perform macOS system updates
update_macos_system() {
    log "Checking for macOS system updates..."

    # Check for available updates
    local updates_available=$(softwareupdate -l 2>&1)

    if echo "$updates_available" | grep -q "No new software available"; then
        log_success "macOS is up to date"
    else
        log "Installing macOS system updates (this may take a while)..."
        sudo softwareupdate -ia --verbose
        log_success "macOS system updates installed"

        # Check if restart is required
        if echo "$updates_available" | grep -q "restart"; then
            log_warning "A system restart is recommended to complete updates"
            read -p "Do you want to restart now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Restarting system in 60 seconds... (Press Ctrl+C to cancel)"
                sudo shutdown -r +1
            fi
        fi
    fi
}

# Function to update Homebrew and installed packages
update_homebrew() {
    log "Updating Homebrew..."
    brew update
    log_success "Homebrew updated"

    log "Upgrading installed Homebrew packages..."
    brew upgrade
    log_success "Homebrew packages upgraded"

    log "Cleaning up old Homebrew versions..."
    brew cleanup
    log_success "Homebrew cleanup complete"
}

# Function to install a cask application
install_cask() {
    local app=$1
    if brew list --cask "$app" &> /dev/null; then
        log_success "$app is already installed"
    else
        log "Installing $app..."
        brew install --cask "$app" && log_success "$app installed" || log_error "Failed to install $app"
    fi
}

# Function to install a CLI tool
install_formula() {
    local tool=$1
    if brew list "$tool" &> /dev/null; then
        log_success "$tool is already installed"
    else
        log "Installing $tool..."
        brew install "$tool" && log_success "$tool installed" || log_error "Failed to install $tool"
    fi
}

# Function to create desktop shortcuts
create_desktop_shortcuts() {
    log "Creating desktop shortcuts..."

    local desktop_path="$HOME/Desktop"

    # Array of applications to create shortcuts for
    declare -A apps=(
        ["Cursor"]="/Applications/Cursor.app"
        ["Visual Studio Code"]="/Applications/Visual Studio Code.app"
        ["iTerm"]="/Applications/iTerm.app"
        ["Docker"]="/Applications/Docker.app"
        ["Podman Desktop"]="/Applications/Podman Desktop.app"
        ["Postman"]="/Applications/Postman.app"
        ["GitHub Desktop"]="/Applications/GitHub Desktop.app"
        ["IntelliJ IDEA CE"]="/Applications/IntelliJ IDEA CE.app"
        ["Obsidian"]="/Applications/Obsidian.app"
    )

    for app_name in "${!apps[@]}"; do
        local app_path="${apps[$app_name]}"
        local shortcut_path="$desktop_path/$app_name"

        if [ -d "$app_path" ]; then
            if [ ! -L "$shortcut_path" ] && [ ! -e "$shortcut_path" ]; then
                ln -s "$app_path" "$shortcut_path"
                log_success "Created desktop shortcut for $app_name"
            else
                log_success "Desktop shortcut for $app_name already exists"
            fi
        else
            log_warning "$app_name not found at $app_path, skipping shortcut creation"
        fi
    done
}

# Function to configure GitHub CLI
configure_github_cli() {
    if command -v gh &> /dev/null; then
        log "GitHub CLI (gh) is installed"
        log "To authenticate with GitHub, run: gh auth login"
        log "To configure git to use gh as credential helper, run: gh auth setup-git"
    fi
}

# Function to configure GitLab CLI
configure_gitlab_cli() {
    if command -v glab &> /dev/null; then
        log "GitLab CLI (glab) is installed"
        log "To authenticate with GitLab, run: glab auth login"
    fi
}

# Main execution
log "========================================="
log "Mac Development Environment Setup Script"
log "========================================="

# Install Homebrew if needed
install_homebrew

# Check if system update is needed (every 4 days)
if should_update_system; then
    log_warning "Forced system update required (last update was more than $UPDATE_INTERVAL_DAYS days ago)"

    # Update macOS system
    update_macos_system

    # Update Homebrew
    update_homebrew

    # Mark update as complete
    mark_update_complete
else
    # Still update Homebrew even if system update not needed
    update_homebrew
fi

# --- GUI Applications ---
log "Installing GUI Applications..."
install_cask "docker"
install_cask "podman-desktop"
install_cask "iterm2"
install_cask "visual-studio-code"
install_cask "cursor"             # Cursor AI Code Editor
install_cask "intellij-idea-ce"
install_cask "obsidian"
install_cask "postman"
install_cask "pgadmin4"
install_cask "tableplus"
install_cask "dbeaver-community"
install_cask "mongodb-compass"
install_cask "github"             # GitHub Desktop
# Note: GitLab doesn't have an official desktop app cask
# Use glab CLI (installed below) for GitLab operations

# --- CLI Tools ---
log "Installing CLI Tools..."
install_formula "git"
install_formula "gh"              # GitHub CLI
install_formula "glab"            # GitLab CLI
install_formula "maven"
install_formula "node"
install_formula "python"
install_formula "openjdk"
install_formula "go"
install_formula "dotnet"
install_formula "kubectl"
install_formula "helm"
install_formula "awscli"
install_formula "azure-cli"
install_formula "google-cloud-sdk"
install_formula "terraform"
install_formula "ansible"
install_formula "k9s"
install_formula "curl"
install_formula "httpie"
install_formula "k6"
install_formula "coder"

# Create desktop shortcuts
create_desktop_shortcuts

# Configure GitHub and GitLab CLI
configure_github_cli
configure_gitlab_cli

# Final cleanup
log "Performing final cleanup..."
brew cleanup
brew doctor || log_warning "Homebrew doctor found some issues (non-critical)"

log_success "========================================="
log_success "All requested tools have been installed!"
log_success "========================================="
log "Log file saved to: $LOG_FILE"
log "Next forced system update will occur after: $(date -v+${UPDATE_INTERVAL_DAYS}d '+%Y-%m-%d')"

# Display next steps
echo ""
log "========================================="
log "Next Steps:"
log "========================================="
log "1. GitHub CLI: Run 'gh auth login' to authenticate"
log "2. GitLab CLI: Run 'glab auth login' to authenticate"
log "3. Docker: Start Docker Desktop from Applications or Desktop shortcut"
log "4. Check Desktop for application shortcuts"
log "5. Cursor: Open from Desktop shortcut or Applications folder"
echo ""

