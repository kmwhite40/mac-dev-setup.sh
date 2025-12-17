#!/bin/bash

################################################################################
# Intune Detection Script for M365 Installer
# This script checks if the application is installed correctly
# Exit 0 = Installed, Exit 1 = Not Installed
################################################################################

INSTALL_DIR="/Library/Application Support/M365Installer"
SCRIPT_NAME="m365-installer.sh"
VERSION_FILE="$INSTALL_DIR/version.txt"
MIN_VERSION="1.0.0"

# Check if installation directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Installation directory not found"
    exit 1
fi

# Check if main script exists and is executable
if [ ! -x "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "Main script not found or not executable"
    exit 1
fi

# Check if version file exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Version file not found"
    exit 1
fi

# Read version from file
INSTALLED_VERSION=$(grep "^version=" "$VERSION_FILE" | cut -d'=' -f2)

if [ -z "$INSTALLED_VERSION" ]; then
    echo "Could not determine installed version"
    exit 1
fi

# Check if command wrapper exists
if [ ! -x "/usr/local/bin/m365-install" ]; then
    echo "Command wrapper not found"
    exit 1
fi

echo "M365 Installer version $INSTALLED_VERSION is installed"
exit 0
