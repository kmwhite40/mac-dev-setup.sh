#!/bin/bash

################################################################################
# Intune Uninstallation Script for Compliance Scanner
# This script is called by Intune when uninstalling the application
################################################################################

# Configuration
INSTALL_DIR="/Library/Application Support/ComplianceScanner"
LOG_DIR="/Library/Logs/ComplianceScanner"
INTUNE_LOG="$LOG_DIR/intune-uninstall.log"
LAUNCHAGENT_PLIST="/Library/LaunchDaemons/com.sbsfederal.compliancescanner.plist"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTUNE_LOG"
}

log "========================================="
log "Starting Compliance Scanner Uninstallation"
log "========================================="

# Unload LaunchDaemon if loaded
if [ -f "$LAUNCHAGENT_PLIST" ]; then
    log "Unloading LaunchDaemon..."
    launchctl unload "$LAUNCHAGENT_PLIST" 2>/dev/null || true
    rm -f "$LAUNCHAGENT_PLIST"
    log "LaunchDaemon removed"
fi

# Remove command-line wrapper
if [ -f "/usr/local/bin/compliance-scan" ]; then
    log "Removing command-line wrapper..."
    rm -f "/usr/local/bin/compliance-scan"
    log "Wrapper removed"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    log "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    log "Installation directory removed"
fi

# Keep reports for historical purposes
log "Keeping compliance reports in /Users/Shared/ComplianceReports"
log "Keeping logs in $LOG_DIR for audit trail"

log "========================================="
log "Uninstallation Complete"
log "========================================="
log "Note: Historical reports and logs preserved"
log "To remove all data:"
log "  sudo rm -rf /Users/Shared/ComplianceReports"
log "  sudo rm -rf $LOG_DIR"

exit 0
