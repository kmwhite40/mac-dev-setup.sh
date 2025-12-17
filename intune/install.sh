#!/bin/bash

################################################################################
# Intune Installation Script for Mac Dev Setup
# This script is called by Intune when installing the application
################################################################################

set -e

# Configuration
INSTALL_DIR="/Library/Application Support/MacDevSetup"
SCRIPT_NAME="mac-dev-setup.sh"
LOG_DIR="/Library/Logs/MacDevSetup"
INTUNE_LOG="$LOG_DIR/intune-install.log"

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTUNE_LOG"
}

log "========================================="
log "Starting Intune Installation"
log "========================================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy main script to installation directory
if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    log "Copying $SCRIPT_NAME to $INSTALL_DIR"
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    log "Script copied successfully"
else
    log "ERROR: $SCRIPT_NAME not found in package"
    exit 1
fi

# Copy all documentation files
log "Copying documentation files..."
for doc in README.md QUICK_START.md OPERATIONS.md TROUBLESHOOTING.md INDEX.md PROJECT_STRUCTURE.md; do
    if [ -f "$SCRIPT_DIR/$doc" ]; then
        cp "$SCRIPT_DIR/$doc" "$INSTALL_DIR/"
        log "Copied $doc"
    fi
done

# Create company-specific configuration
cat > "$INSTALL_DIR/company-config.sh" << 'EOF'
#!/bin/bash
# Company-specific configuration
# Edit these values for your organization

COMPANY_NAME="SBS"
IT_SUPPORT_EMAIL="it@sbsfederal.com"
UPDATE_INTERVAL_DAYS=4
SKIP_MACOS_UPDATES=false  # Set to true to skip system updates in corporate environment
ENABLE_LOGGING=true
EOF

chmod +x "$INSTALL_DIR/company-config.sh"
log "Created company configuration file"

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
# Uninstall script for Mac Dev Setup

echo "Uninstalling Mac Dev Setup..."

# Remove desktop shortcuts
rm -f "$HOME/Desktop/Cursor"
rm -f "$HOME/Desktop/Visual Studio Code"
rm -f "$HOME/Desktop/iTerm"
rm -f "$HOME/Desktop/Docker"
rm -f "$HOME/Desktop/Postman"
rm -f "$HOME/Desktop/GitHub Desktop"
rm -f "$HOME/Desktop/IntelliJ IDEA CE"
rm -f "$HOME/Desktop/Obsidian"

# Remove user tracking file (keep logs)
rm -f "$HOME/.mac-dev-setup-last-update"

echo "Uninstall complete. Note: Installed applications were NOT removed."
echo "To remove applications, use: brew uninstall --cask <app-name>"
EOF

chmod +x "$INSTALL_DIR/uninstall.sh"
log "Created uninstall script"

# Create LaunchAgent for automatic updates (optional)
LAUNCHAGENT_DIR="/Library/LaunchAgents"
LAUNCHAGENT_PLIST="com.company.macdevsetup.plist"

mkdir -p "$LAUNCHAGENT_DIR"

cat > "$LAUNCHAGENT_DIR/$LAUNCHAGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.company.macdevsetup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$INSTALL_DIR/$SCRIPT_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/launchagent-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/launchagent-stderr.log</string>
</dict>
</plist>
EOF

log "Created LaunchAgent (disabled by default)"

# Create wrapper script for user execution
cat > "/usr/local/bin/mac-dev-setup" << EOF
#!/bin/bash
# Wrapper script to run Mac Dev Setup from anywhere

"$INSTALL_DIR/$SCRIPT_NAME" "\$@"
EOF

chmod +x "/usr/local/bin/mac-dev-setup"
log "Created command-line wrapper: mac-dev-setup"

# Create status/version file for Intune detection
cat > "$INSTALL_DIR/version.txt" << EOF
version=2.0
install_date=$(date +%Y-%m-%d)
installed_by=Intune
EOF

log "Created version file for detection"

# Set appropriate permissions
chown -R root:admin "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

log "========================================="
log "Installation Complete"
log "========================================="
log "Installation directory: $INSTALL_DIR"
log "Command available: mac-dev-setup"
log "Logs directory: $LOG_DIR"
log ""
log "User can now run: mac-dev-setup"
log "Or manually: $INSTALL_DIR/$SCRIPT_NAME"

exit 0
