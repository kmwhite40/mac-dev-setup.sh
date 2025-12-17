#!/bin/bash

################################################################################
# Intune Uninstallation Script for Mac Dev Setup
# This script is called by Intune when uninstalling the application
################################################################################

# Configuration
INSTALL_DIR="/Library/Application Support/MacDevSetup"
LOG_DIR="/Library/Logs/MacDevSetup"
INTUNE_LOG="$LOG_DIR/intune-uninstall.log"
LAUNCHAGENT_PLIST="/Library/LaunchAgents/com.company.macdevsetup.plist"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTUNE_LOG"
}

log "========================================="
log "Starting Intune Uninstallation"
log "========================================="

# Unload LaunchAgent if loaded
if [ -f "$LAUNCHAGENT_PLIST" ]; then
    log "Unloading LaunchAgent..."
    launchctl unload "$LAUNCHAGENT_PLIST" 2>/dev/null || true
    rm -f "$LAUNCHAGENT_PLIST"
    log "LaunchAgent removed"
fi

# Remove command-line wrapper
if [ -f "/usr/local/bin/mac-dev-setup" ]; then
    log "Removing command-line wrapper..."
    rm -f "/usr/local/bin/mac-dev-setup"
    log "Wrapper removed"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    log "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    log "Installation directory removed"
fi

# Clean up user-specific files (for all users)
log "Cleaning up user-specific files..."
for user_home in /Users/*; do
    if [ -d "$user_home" ] && [ "$user_home" != "/Users/Shared" ]; then
        # Remove desktop shortcuts
        rm -f "$user_home/Desktop/Cursor"
        rm -f "$user_home/Desktop/Visual Studio Code"
        rm -f "$user_home/Desktop/iTerm"
        rm -f "$user_home/Desktop/Docker"
        rm -f "$user_home/Desktop/Postman"
        rm -f "$user_home/Desktop/GitHub Desktop"
        rm -f "$user_home/Desktop/IntelliJ IDEA CE"
        rm -f "$user_home/Desktop/Obsidian"

        # Remove tracking file (keep logs for troubleshooting)
        rm -f "$user_home/.mac-dev-setup-last-update"

        log "Cleaned up files for user: $(basename "$user_home")"
    fi
done

log "========================================="
log "Uninstallation Complete"
log "========================================="
log "Note: Installed applications (Docker, VS Code, etc.) were NOT removed"
log "Note: Homebrew was NOT removed"
log "Note: User logs preserved in $LOG_DIR"
log ""
log "To manually remove applications, users can run:"
log "  brew list --cask | xargs brew uninstall --cask"

exit 0
