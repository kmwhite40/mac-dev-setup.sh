#!/bin/bash

################################################################################
# Intune Post-Installation Script for M365 Installer
# Runs after installation to configure and notify users
################################################################################

LOG_DIR="/Library/Logs/M365Installer"
POSTINSTALL_LOG="$LOG_DIR/postinstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$POSTINSTALL_LOG"
}

log "========================================="
log "Running Post-Installation Tasks"
log "========================================="

# Create user notification script
NOTIFICATION_SCRIPT="/tmp/m365-installer-notification.sh"
cat > "$NOTIFICATION_SCRIPT" << 'EOF'
#!/bin/bash
# This runs as the logged-in user

osascript <<'APPLESCRIPT'
display notification "Microsoft 365 Installer has been installed. Run 'm365-install' in Terminal or use the desktop launcher to install Microsoft 365 applications." with title "M365 Installer Ready" sound name "Glass"
APPLESCRIPT
EOF

chmod +x "$NOTIFICATION_SCRIPT"

# Run notification as logged-in user
CURRENT_USER=$(stat -f%Su /dev/console)
if [ "$CURRENT_USER" != "root" ] && [ "$CURRENT_USER" != "_mbsetupuser" ]; then
    log "Sending notification to user: $CURRENT_USER"
    sudo -u "$CURRENT_USER" "$NOTIFICATION_SCRIPT" &
fi

rm -f "$NOTIFICATION_SCRIPT"

log "========================================="
log "Post-Installation Complete"
log "========================================="
log "Users can now run: m365-install"
log "Or use: /Users/Shared/Install Microsoft 365.command"

exit 0
