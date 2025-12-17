#!/bin/bash

################################################################################
# Intune Detection Script for Mac Dev Setup
# This script checks if the application is installed correctly
# Exit 0 = Installed, Exit 1 = Not Installed
################################################################################

INSTALL_DIR="/Library/Application Support/MacDevSetup"
SCRIPT_NAME="mac-dev-setup.sh"
VERSION_FILE="$INSTALL_DIR/version.txt"
MIN_VERSION="2.0"

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

# Version comparison (simple string comparison for x.y format)
if [ "$(printf '%s\n' "$MIN_VERSION" "$INSTALLED_VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
    echo "Mac Dev Setup version $INSTALLED_VERSION is installed"
    exit 0
else
    echo "Installed version $INSTALLED_VERSION is older than required $MIN_VERSION"
    exit 1
fi
