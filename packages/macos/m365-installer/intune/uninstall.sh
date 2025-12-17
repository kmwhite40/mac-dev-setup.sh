#!/bin/bash

################################################################################
# Intune Uninstallation Script for M365 Installer
# This script is called by Intune when uninstalling the application
################################################################################

# Configuration
INSTALL_DIR="/Library/Application Support/M365Installer"
LOG_DIR="/Library/Logs/M365Installer"
INTUNE_LOG="$LOG_DIR/intune-uninstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTUNE_LOG"
}

log "========================================="
log "Starting M365 Installer Uninstallation"
log "========================================="

# Remove command-line wrapper
if [ -f "/usr/local/bin/m365-install" ]; then
    log "Removing command-line wrapper..."
    rm -f "/usr/local/bin/m365-install"
    log "Wrapper removed"
fi

# Remove desktop launcher
if [ -f "/Users/Shared/Install Microsoft 365.command" ]; then
    log "Removing desktop launcher..."
    rm -f "/Users/Shared/Install Microsoft 365.command"
    log "Launcher removed"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    log "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    log "Installation directory removed"
fi

# Keep logs for audit trail
log "Keeping logs in $LOG_DIR for audit purposes"

log "========================================="
log "Uninstallation Complete"
log "========================================="
log "Note: Microsoft 365 applications were NOT uninstalled"
log "To remove M365 apps, uninstall them individually from Applications folder"
log "Or use: /Applications/Microsoft\ Office\ 2019/Remove\ Office.app (if available)"

exit 0
