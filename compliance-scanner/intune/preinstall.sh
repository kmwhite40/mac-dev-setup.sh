#!/bin/bash

################################################################################
# Intune Pre-Installation Script for Compliance Scanner
# Runs before installation to check prerequisites
################################################################################

LOG_DIR="/Library/Logs/ComplianceScanner"
mkdir -p "$LOG_DIR"
PREINSTALL_LOG="$LOG_DIR/preinstall.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$PREINSTALL_LOG"
}

log "========================================="
log "Running Pre-Installation Checks"
log "========================================="

# Check macOS version (require 10.15+)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo "$OS_VERSION" | cut -d'.' -f1)
OS_MINOR=$(echo "$OS_VERSION" | cut -d'.' -f2)

log "Detected macOS version: $OS_VERSION"

if [ "$OS_MAJOR" -lt 10 ] || ([ "$OS_MAJOR" -eq 10 ] && [ "$OS_MINOR" -lt 15 ]); then
    log "ERROR: macOS 10.15 or higher is required"
    exit 1
fi
log "✓ macOS version check passed"

# Check available disk space (require at least 1GB)
AVAILABLE_SPACE=$(df -g / | awk 'NR==2 {print $4}')
log "Available disk space: ${AVAILABLE_SPACE}GB"

if [ "$AVAILABLE_SPACE" -lt 1 ]; then
    log "ERROR: Insufficient disk space. At least 1GB required."
    exit 1
fi
log "✓ Disk space check passed"

# Check architecture
ARCH=$(uname -m)
log "System architecture: $ARCH"
if [ "$ARCH" = "arm64" ]; then
    log "✓ Apple Silicon (M1/M2/M3) detected"
elif [ "$ARCH" = "x86_64" ]; then
    log "✓ Intel Mac detected"
else
    log "WARNING: Unknown architecture: $ARCH"
fi

log "========================================="
log "Pre-Installation Checks Complete"
log "========================================="
log "System is ready for Compliance Scanner installation"

exit 0
