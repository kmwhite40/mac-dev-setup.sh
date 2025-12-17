#!/bin/bash

################################################################################
# Intune Post-Installation Script for Compliance Scanner
# Runs after installation to configure and notify users
################################################################################

LOG_DIR="/Library/Logs/ComplianceScanner"
POSTINSTALL_LOG="$LOG_DIR/postinstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$POSTINSTALL_LOG"
}

log "========================================="
log "Running Post-Installation Tasks"
log "========================================="

# Create user notification script
NOTIFICATION_SCRIPT="/tmp/compliance-scanner-notification.sh"
cat > "$NOTIFICATION_SCRIPT" << 'EOF'
#!/bin/bash
# This runs as the logged-in user

osascript <<'APPLESCRIPT'
display notification "NIST 800-53 Compliance Scanner has been installed. Run 'compliance-scan' in Terminal to perform a security compliance check." with title "Compliance Scanner Installed" sound name "Glass"
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

# Create desktop shortcut to run scanner (optional)
INSTALL_DIR="/Library/Application Support/ComplianceScanner"
cat > "/Users/Shared/Run Compliance Scan.command" << 'EOF'
#!/bin/bash
clear
echo "========================================="
echo "NIST 800-53 Compliance Scanner"
echo "SBS Federal"
echo "========================================="
echo ""
/usr/local/bin/compliance-scan
echo ""
echo "Press any key to close..."
read -n 1
EOF

chmod +x "/Users/Shared/Run Compliance Scan.command"
log "Created desktop launcher in /Users/Shared"

log "========================================="
log "Post-Installation Complete"
log "========================================="
log "Users can now run: compliance-scan"
log "Or use: /Users/Shared/Run Compliance Scan.command"

exit 0
