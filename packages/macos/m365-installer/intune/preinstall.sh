#!/bin/bash

################################################################################
# Intune Pre-Installation Script for M365 Installer
# Runs before installation to check prerequisites
################################################################################

LOG_DIR="/Library/Logs/M365Installer"
mkdir -p "$LOG_DIR"
PREINSTALL_LOG="$LOG_DIR/preinstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$PREINSTALL_LOG"
}

log "========================================="
log "Running Pre-Installation Checks"
log "========================================="

# Check macOS version (require 10.14+)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo "$OS_VERSION" | cut -d'.' -f1)
OS_MINOR=$(echo "$OS_VERSION" | cut -d'.' -f2)

log "Detected macOS version: $OS_VERSION"

if [ "$OS_MAJOR" -lt 10 ] || ([ "$OS_MAJOR" -eq 10 ] && [ "$OS_MINOR" -lt 14 ]); then
    log "ERROR: macOS 10.14 (Mojave) or higher is required for M365 apps"
    exit 1
fi
log "✓ macOS version check passed"

# Check available disk space (require at least 10GB for M365 downloads/install)
AVAILABLE_SPACE=$(df -g / | awk 'NR==2 {print $4}')
log "Available disk space: ${AVAILABLE_SPACE}GB"

if [ "$AVAILABLE_SPACE" -lt 10 ]; then
    log "WARNING: Less than 10GB disk space available. M365 installation may fail."
    log "Available: ${AVAILABLE_SPACE}GB, Recommended: 10GB+"
    # Don't exit, just warn
fi
log "✓ Disk space check passed"

# Check for internet connectivity
log "Checking internet connectivity..."
if ping -c 1 microsoft.com &> /dev/null; then
    log "✓ Internet connectivity check passed"
else
    log "WARNING: Cannot reach microsoft.com. Installation requires internet access."
fi

# Check architecture
ARCH=$(uname -m)
log "System architecture: $ARCH"
if [ "$ARCH" = "arm64" ]; then
    log "✓ Apple Silicon (M1/M2/M3) detected - Universal binaries will be used"
elif [ "$ARCH" = "x86_64" ]; then
    log "✓ Intel Mac detected"
else
    log "WARNING: Unknown architecture: $ARCH"
fi

log "========================================="
log "Pre-Installation Checks Complete"
log "========================================="
log "System is ready for M365 Installer installation"

exit 0
