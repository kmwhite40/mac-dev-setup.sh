#!/bin/bash

################################################################################
# Microsoft 365 Applications Installer for macOS
# Version: 1.0.0
# Company: SBS Federal
#
# This script automatically downloads and installs Microsoft 365 applications
# for macOS with comprehensive logging and error handling.
################################################################################

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
COMPANY_NAME="SBS Federal"
SCRIPT_VERSION="1.0.0"
LOG_DIR="$HOME/.m365-installer"
DOWNLOAD_DIR="$LOG_DIR/downloads"
LOG_FILE="$LOG_DIR/installer.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Installation tracking
TOTAL_APPS=0
INSTALLED_APPS=0
FAILED_APPS=0
SKIPPED_APPS=0

# Create necessary directories
mkdir -p "$LOG_DIR"
mkdir -p "$DOWNLOAD_DIR"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a "$LOG_FILE"
    ((INSTALLED_APPS++))
    ((TOTAL_APPS++))
}

log_fail() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"
    ((FAILED_APPS++))
    ((TOTAL_APPS++))
}

log_skip() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⏭️  $1${NC}" | tee -a "$LOG_FILE"
    ((SKIPPED_APPS++))
    ((TOTAL_APPS++))
}

log_info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_fail "Please do not run this script as root or with sudo"
    exit 1
fi

# Function to check available disk space
check_disk_space() {
    log_info "Checking available disk space..."

    local available_gb=$(df -g / | awk 'NR==2 {print $4}')
    local required_gb=10

    if [ "$available_gb" -lt "$required_gb" ]; then
        log_fail "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        exit 1
    fi

    log_success "Sufficient disk space available: ${available_gb}GB"
}

# Function to check if application is already installed
is_app_installed() {
    local app_name="$1"
    local app_path="/Applications/$app_name.app"

    if [ -d "$app_path" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get application version
get_app_version() {
    local app_name="$1"
    local app_path="/Applications/$app_name.app"

    if [ -d "$app_path" ]; then
        defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

# Function to download file with progress
download_file() {
    local url="$1"
    local output_file="$2"
    local app_name="$3"

    log_info "Downloading $app_name..."

    if curl -L -# -o "$output_file" "$url"; then
        log_success "Downloaded $app_name"
        return 0
    else
        log_fail "Failed to download $app_name"
        return 1
    fi
}

# Function to mount DMG
mount_dmg() {
    local dmg_file="$1"

    log_info "Mounting disk image..."

    local mount_point=$(hdiutil attach "$dmg_file" -nobrowse | grep "/Volumes/" | awk '{print $NF}')
    echo "$mount_point"
}

# Function to unmount DMG
unmount_dmg() {
    local mount_point="$1"

    if [ -n "$mount_point" ]; then
        log_info "Unmounting disk image..."
        hdiutil detach "$mount_point" -quiet 2>/dev/null || true
    fi
}

# Function to install PKG file
install_pkg() {
    local pkg_file="$1"
    local app_name="$2"

    log_info "Installing $app_name..."

    if sudo installer -pkg "$pkg_file" -target / -verbose; then
        log_success "$app_name installed successfully"
        return 0
    else
        log_fail "Failed to install $app_name"
        return 1
    fi
}

# Function to copy app from DMG
copy_app_from_dmg() {
    local mount_point="$1"
    local app_name="$2"

    log_info "Copying $app_name to Applications..."

    # Find .app in mount point
    local app_path=$(find "$mount_point" -maxdepth 2 -name "*.app" | head -1)

    if [ -n "$app_path" ]; then
        if sudo cp -R "$app_path" /Applications/; then
            log_success "$app_name copied successfully"
            return 0
        else
            log_fail "Failed to copy $app_name"
            return 1
        fi
    else
        log_fail "Could not find .app in DMG"
        return 1
    fi
}

# Function to install from PKG in DMG
install_from_dmg_pkg() {
    local mount_point="$1"
    local app_name="$2"

    # Find .pkg in mount point
    local pkg_path=$(find "$mount_point" -maxdepth 2 -name "*.pkg" | head -1)

    if [ -n "$pkg_path" ]; then
        install_pkg "$pkg_path" "$app_name"
        return $?
    else
        log_fail "Could not find .pkg in DMG"
        return 1
    fi
}

################################################################################
# Microsoft 365 Application Installation Functions
################################################################################

# Microsoft 365 Suite (Office)
install_microsoft_365_suite() {
    local app_name="Microsoft Office"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Word"; then
        local version=$(get_app_version "Microsoft Word")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Download Office Suite installer
    # Using Microsoft's official CDN URL
    local url="https://go.microsoft.com/fwlink/?linkid=525133"
    local pkg_file="$DOWNLOAD_DIR/MicrosoftOffice.pkg"

    if download_file "$url" "$pkg_file" "$app_name"; then
        if install_pkg "$pkg_file" "$app_name"; then
            log_success "$app_name installation complete"
        else
            log_fail "$app_name installation failed"
        fi
        rm -f "$pkg_file"
    fi
}

# Microsoft Teams
install_microsoft_teams() {
    local app_name="Microsoft Teams"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Teams"; then
        local version=$(get_app_version "Microsoft Teams")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Microsoft Teams download URL
    local url="https://go.microsoft.com/fwlink/?linkid=869428"
    local pkg_file="$DOWNLOAD_DIR/MicrosoftTeams.pkg"

    if download_file "$url" "$pkg_file" "$app_name"; then
        if install_pkg "$pkg_file" "$app_name"; then
            log_success "$app_name installation complete"
        else
            log_fail "$app_name installation failed"
        fi
        rm -f "$pkg_file"
    fi
}

# Microsoft OneDrive
install_microsoft_onedrive() {
    local app_name="OneDrive"
    log_info "===== Installing $app_name ====="

    if is_app_installed "OneDrive"; then
        local version=$(get_app_version "OneDrive")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # OneDrive download URL
    local url="https://go.microsoft.com/fwlink/?linkid=823060"
    local pkg_file="$DOWNLOAD_DIR/OneDrive.pkg"

    if download_file "$url" "$pkg_file" "$app_name"; then
        if install_pkg "$pkg_file" "$app_name"; then
            log_success "$app_name installation complete"
        else
            log_fail "$app_name installation failed"
        fi
        rm -f "$pkg_file"
    fi
}

# Microsoft Outlook
install_microsoft_outlook() {
    local app_name="Microsoft Outlook"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Outlook"; then
        local version=$(get_app_version "Microsoft Outlook")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Outlook is part of Office Suite
    log_info "$app_name is installed as part of Microsoft 365 Suite"
    if is_app_installed "Microsoft Word"; then
        log_skip "$app_name available via Office Suite"
    else
        log_warning "$app_name requires Office Suite installation"
    fi
}

# Microsoft OneNote
install_microsoft_onenote() {
    local app_name="Microsoft OneNote"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft OneNote"; then
        local version=$(get_app_version "Microsoft OneNote")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # OneNote is part of Office Suite
    log_info "$app_name is installed as part of Microsoft 365 Suite"
    if is_app_installed "Microsoft Word"; then
        log_skip "$app_name available via Office Suite"
    else
        log_warning "$app_name requires Office Suite installation"
    fi
}

# Microsoft Edge
install_microsoft_edge() {
    local app_name="Microsoft Edge"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Edge"; then
        local version=$(get_app_version "Microsoft Edge")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Edge download URL
    local url="https://go.microsoft.com/fwlink/?linkid=2093504"
    local pkg_file="$DOWNLOAD_DIR/MicrosoftEdge.pkg"

    if download_file "$url" "$pkg_file" "$app_name"; then
        if install_pkg "$pkg_file" "$app_name"; then
            log_success "$app_name installation complete"
        else
            log_fail "$app_name installation failed"
        fi
        rm -f "$pkg_file"
    fi
}

# Microsoft Remote Desktop
install_microsoft_remote_desktop() {
    local app_name="Microsoft Remote Desktop"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Remote Desktop"; then
        local version=$(get_app_version "Microsoft Remote Desktop")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    log_info "$app_name can be installed from Mac App Store"
    log_info "App Store link: https://apps.apple.com/app/microsoft-remote-desktop/id1295203466"
    log_skip "$app_name (available via App Store)"
}

# Microsoft Defender (formerly ATP)
install_microsoft_defender() {
    local app_name="Microsoft Defender"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Defender"; then
        local version=$(get_app_version "Microsoft Defender")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    log_warning "$app_name typically deployed via Intune/MDM"
    log_info "Manual download available from Microsoft Defender portal"
    log_skip "$app_name (requires MDM deployment)"
}

# Microsoft PowerPoint
install_microsoft_powerpoint() {
    local app_name="Microsoft PowerPoint"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft PowerPoint"; then
        local version=$(get_app_version "Microsoft PowerPoint")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # PowerPoint is part of Office Suite
    log_info "$app_name is installed as part of Microsoft 365 Suite"
    if is_app_installed "Microsoft Word"; then
        log_skip "$app_name available via Office Suite"
    else
        log_warning "$app_name requires Office Suite installation"
    fi
}

# Microsoft Excel
install_microsoft_excel() {
    local app_name="Microsoft Excel"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft Excel"; then
        local version=$(get_app_version "Microsoft Excel")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Excel is part of Office Suite
    log_info "$app_name is installed as part of Microsoft 365 Suite"
    if is_app_installed "Microsoft Word"; then
        log_skip "$app_name available via Office Suite"
    else
        log_warning "$app_name requires Office Suite installation"
    fi
}

# Microsoft To Do
install_microsoft_todo() {
    local app_name="Microsoft To Do"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Microsoft To Do"; then
        local version=$(get_app_version "Microsoft To Do")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    log_info "$app_name can be installed from Mac App Store"
    log_info "App Store link: https://apps.apple.com/app/microsoft-to-do/id1274495053"
    log_skip "$app_name (available via App Store)"
}

# Company Portal
install_company_portal() {
    local app_name="Company Portal"
    log_info "===== Installing $app_name ====="

    if is_app_installed "Company Portal"; then
        local version=$(get_app_version "Company Portal")
        log_skip "$app_name already installed (version: $version)"
        return
    fi

    # Company Portal download URL
    local url="https://go.microsoft.com/fwlink/?linkid=853070"
    local pkg_file="$DOWNLOAD_DIR/CompanyPortal.pkg"

    if download_file "$url" "$pkg_file" "$app_name"; then
        if install_pkg "$pkg_file" "$app_name"; then
            log_success "$app_name installation complete"
        else
            log_fail "$app_name installation failed"
        fi
        rm -f "$pkg_file"
    fi
}

################################################################################
# Post-Installation Configuration
################################################################################

configure_office_updates() {
    log_info "Configuring Microsoft AutoUpdate..."

    # Enable automatic updates for Office apps
    if [ -d "/Library/Application Support/Microsoft/MAU2.0" ]; then
        defaults write com.microsoft.autoupdate2 HowToCheck AutomaticDownload 2>/dev/null || true
        log_success "Automatic updates enabled for Microsoft apps"
    else
        log_info "Microsoft AutoUpdate not found (will be available after first Office app launch)"
    fi
}

create_desktop_shortcuts() {
    log_info "Creating desktop shortcuts..."

    local desktop_path="$HOME/Desktop"

    declare -A apps=(
        ["Microsoft Word"]="/Applications/Microsoft Word.app"
        ["Microsoft Excel"]="/Applications/Microsoft Excel.app"
        ["Microsoft PowerPoint"]="/Applications/Microsoft PowerPoint.app"
        ["Microsoft Outlook"]="/Applications/Microsoft Outlook.app"
        ["Microsoft Teams"]="/Applications/Microsoft Teams.app"
        ["Microsoft Edge"]="/Applications/Microsoft Edge.app"
        ["OneDrive"]="/Applications/OneDrive.app"
    )

    for app_name in "${!apps[@]}"; do
        local app_path="${apps[$app_name]}"
        local shortcut_path="$desktop_path/$app_name"

        if [ -d "$app_path" ]; then
            if [ ! -L "$shortcut_path" ] && [ ! -e "$shortcut_path" ]; then
                ln -s "$app_path" "$shortcut_path"
                log_success "Created desktop shortcut for $app_name"
            fi
        fi
    done
}

show_post_install_instructions() {
    log ""
    log "========================================="
    log "POST-INSTALLATION INSTRUCTIONS"
    log "========================================="
    log ""
    log "1. Sign in to Microsoft 365:"
    log "   - Open any Office app (Word, Excel, etc.)"
    log "   - Click 'Sign In' and use your SBS Federal credentials"
    log "   - Format: username@sbsfederal.com"
    log ""
    log "2. Set up OneDrive:"
    log "   - Open OneDrive from Applications or Desktop"
    log "   - Sign in with your SBS Federal credentials"
    log "   - Choose folders to sync"
    log ""
    log "3. Configure Microsoft Teams:"
    log "   - Open Microsoft Teams"
    log "   - Sign in with your SBS Federal credentials"
    log "   - Configure notifications and preferences"
    log ""
    log "4. Check for Updates:"
    log "   - Microsoft AutoUpdate will run automatically"
    log "   - Or manually: Open any Office app → Help → Check for Updates"
    log ""
    log "5. Company Portal (if installed):"
    log "   - Sign in to access corporate resources"
    log "   - Install additional apps as needed"
    log ""
    log "For support, contact: it@sbsfederal.com"
    log "========================================="
}

################################################################################
# Main Execution
################################################################################

main() {
    log "========================================="
    log "Microsoft 365 Applications Installer"
    log "$COMPANY_NAME"
    log "Version: $SCRIPT_VERSION"
    log "========================================="
    log ""

    # Check prerequisites
    check_disk_space
    log ""

    # Install applications
    log "========================================="
    log "INSTALLING MICROSOFT 365 APPLICATIONS"
    log "========================================="
    log ""

    install_microsoft_365_suite
    log ""

    install_microsoft_teams
    log ""

    install_microsoft_onedrive
    log ""

    install_microsoft_edge
    log ""

    install_company_portal
    log ""

    # Check Office Suite components
    log "========================================="
    log "VERIFYING OFFICE SUITE COMPONENTS"
    log "========================================="
    log ""

    install_microsoft_outlook
    install_microsoft_excel
    install_microsoft_powerpoint
    install_microsoft_onenote
    log ""

    # Optional applications (App Store or MDM)
    log "========================================="
    log "OPTIONAL APPLICATIONS"
    log "========================================="
    log ""

    install_microsoft_remote_desktop
    install_microsoft_todo
    install_microsoft_defender
    log ""

    # Post-installation configuration
    log "========================================="
    log "POST-INSTALLATION CONFIGURATION"
    log "========================================="
    log ""

    configure_office_updates
    create_desktop_shortcuts
    log ""

    # Clean up
    log "Cleaning up temporary files..."
    rm -rf "$DOWNLOAD_DIR"/*.pkg 2>/dev/null || true
    log_success "Cleanup complete"
    log ""

    # Final Summary
    log "========================================="
    log "INSTALLATION COMPLETE"
    log "========================================="
    log ""
    log "Total Applications: $TOTAL_APPS"
    log_success "Successfully Installed: $INSTALLED_APPS"
    log_skip "Already Installed/Skipped: $SKIPPED_APPS"
    log_fail "Failed: $FAILED_APPS"
    log ""
    log "Log file: $LOG_FILE"
    log ""

    # Show post-install instructions
    show_post_install_instructions

    log "========================================="
    log "Thank you for using $COMPANY_NAME IT Tools"
    log "========================================="
}

# Run main function
main "$@"
