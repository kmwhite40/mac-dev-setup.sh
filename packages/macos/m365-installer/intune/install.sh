#!/bin/bash

################################################################################
# Intune Installation Script for M365 Installer
# This script is called by Intune when installing the application
################################################################################

set -e

# Configuration
INSTALL_DIR="/Library/Application Support/M365Installer"
SCRIPT_NAME="m365-installer.sh"
LOG_DIR="/Library/Logs/M365Installer"
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
log "Starting M365 Installer Installation"
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
cat > "/usr/local/bin/m365-install" << EOF
#!/bin/bash
# Wrapper script to run M365 Installer from anywhere

"$INSTALL_DIR/$SCRIPT_NAME" "\$@"
EOF

chmod +x "/usr/local/bin/m365-install"
log "Created command-line wrapper: m365-install"

# Create desktop launcher
cat > "/Users/Shared/Install Microsoft 365.command" << 'EOF'
#!/bin/bash
clear
echo "========================================="
echo "Microsoft 365 Applications Installer"
echo "SBS Federal"
echo "========================================="
echo ""
/usr/local/bin/m365-install
echo ""
echo "Press any key to close..."
read -n 1
EOF

chmod +x "/Users/Shared/Install Microsoft 365.command"
log "Created desktop launcher in /Users/Shared"

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

log "========================================="
log "Installation Complete"
log "========================================="
log "Installation directory: $INSTALL_DIR"
log "Command available: m365-install"
log "Logs directory: $LOG_DIR"
log "Desktop launcher: /Users/Shared/Install Microsoft 365.command"
log ""
log "Users can now run: m365-install"
log "Or use desktop launcher to install Microsoft 365 apps"

exit 0
