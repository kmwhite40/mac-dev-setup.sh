#!/bin/bash

################################################################################
# Intune Installation Script for NIST 800-53 Compliance Scanner
# This script is called by Intune when installing the application
################################################################################

set -e

# Configuration
INSTALL_DIR="/Library/Application Support/ComplianceScanner"
SCRIPT_NAME="nist-800-53-scanner.sh"
LOG_DIR="/Library/Logs/ComplianceScanner"
INTUNE_LOG="$LOG_DIR/intune-install.log"
COMPANY_NAME="SBS Federal"

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$LOG_DIR"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTUNE_LOG"
}

log "========================================="
log "Starting Compliance Scanner Installation"
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

# Create wrapper script for user execution
cat > "/usr/local/bin/compliance-scan" << EOF
#!/bin/bash
# Wrapper script to run Compliance Scanner from anywhere

"$INSTALL_DIR/$SCRIPT_NAME" "\$@"
EOF

chmod +x "/usr/local/bin/compliance-scan"
log "Created command-line wrapper: compliance-scan"

# Create LaunchDaemon for scheduled scans (weekly on Monday at 9 AM)
LAUNCHAGENT_DIR="/Library/LaunchDaemons"
LAUNCHAGENT_PLIST="com.sbsfederal.compliancescanner.plist"

mkdir -p "$LAUNCHAGENT_DIR"

cat > "$LAUNCHAGENT_DIR/$LAUNCHAGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.sbsfederal.compliancescanner</string>
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
    <string>$LOG_DIR/scheduled-scan-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/scheduled-scan-stderr.log</string>
</dict>
</plist>
EOF

log "Created LaunchDaemon for scheduled scans (disabled by default)"

# Create status/version file for Intune detection
cat > "$INSTALL_DIR/version.txt" << EOF
version=1.0.0
install_date=$(date +%Y-%m-%d)
installed_by=Intune
company=$COMPANY_NAME
EOF

log "Created version file for detection"

# Set appropriate permissions
chown -R root:wheel "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

# Create initial report directory for all users
mkdir -p "/Users/Shared/ComplianceReports"
chmod 777 "/Users/Shared/ComplianceReports"
log "Created shared reports directory"

log "========================================="
log "Installation Complete"
log "========================================="
log "Installation directory: $INSTALL_DIR"
log "Command available: compliance-scan"
log "Logs directory: $LOG_DIR"
log "Shared reports: /Users/Shared/ComplianceReports"
log ""
log "User can now run: compliance-scan"
log "Or manually: $INSTALL_DIR/$SCRIPT_NAME"
log ""
log "To enable weekly automated scans:"
log "  sudo launchctl load -w $LAUNCHAGENT_DIR/$LAUNCHAGENT_PLIST"

exit 0
