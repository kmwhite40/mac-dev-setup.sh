#!/bin/bash

################################################################################
# Intune Post-Installation Script for Mac Dev Setup
# Runs after installation to configure and notify users
################################################################################

LOG_DIR="/Library/Logs/MacDevSetup"
POSTINSTALL_LOG="$LOG_DIR/postinstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$POSTINSTALL_LOG"
}

log "========================================="
log "Running Post-Installation Tasks"
log "========================================="

# Create user notification script
NOTIFICATION_SCRIPT="/tmp/mac-dev-setup-notification.sh"
cat > "$NOTIFICATION_SCRIPT" << 'EOF'
#!/bin/bash
# This runs as the logged-in user

osascript <<'APPLESCRIPT'
display notification "Mac Dev Setup has been installed via Company Portal. Run 'mac-dev-setup' in Terminal to configure your development environment." with title "Mac Dev Setup Installed" sound name "Glass"
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

# Create welcome message file that shows on first run
INSTALL_DIR="/Library/Application Support/MacDevSetup"
cat > "$INSTALL_DIR/WELCOME.txt" << 'EOF'
========================================
Welcome to Mac Dev Setup
========================================

This tool has been deployed via Intune Company Portal.

FIRST TIME USAGE:
1. Open Terminal
2. Run: mac-dev-setup
3. Follow the on-screen instructions

The script will:
- Install Homebrew (if needed)
- Update macOS (every 4 days)
- Install development tools and applications
- Create desktop shortcuts
- Log all activities

DOCUMENTATION:
- Quick Start: /Library/Application Support/MacDevSetup/QUICK_START.md
- Full Docs: /Library/Application Support/MacDevSetup/README.md
- Troubleshooting: /Library/Application Support/MacDevSetup/TROUBLESHOOTING.md

SUPPORT:
For IT support, contact: itsupport@company.com

LOGS:
All operations are logged to:
- System: /Library/Logs/MacDevSetup/
- User: ~/.mac-dev-setup.log

========================================
EOF

log "Created welcome message"

# Set up auto-update check (optional - configure based on company policy)
# Uncomment to enable automatic weekly runs
# launchctl load /Library/LaunchAgents/com.company.macdevsetup.plist
log "LaunchAgent created but not loaded (manual activation required)"

# Create desktop shortcut to documentation for admin users
ADMIN_DESKTOP="/Users/Shared/Mac Dev Setup Documentation"
ln -sf "$INSTALL_DIR" "$ADMIN_DESKTOP" 2>/dev/null || true
log "Created documentation shortcut in /Users/Shared"

log "========================================="
log "Post-Installation Complete"
log "========================================="
log "Users can now run: mac-dev-setup"

exit 0
