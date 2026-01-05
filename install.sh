#!/bin/bash
#===============================================================================
# SBS Federal - Mac Development Environment Installer
#
# One-line installation:
#   curl -fsSL https://raw.githubusercontent.com/kmwhite40/mac-dev-setup.sh/main/install.sh | bash
#
# Or:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kmwhite40/mac-dev-setup.sh/main/install.sh)"
#
#===============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║       ${GREEN}SBS Federal - Mac Dev Environment Setup${BLUE}            ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║       ${NC}Automated Developer Toolchain Installer${BLUE}              ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please do not run this script as root or with sudo${NC}"
    echo -e "${YELLOW}   Run as: curl -fsSL https://raw.githubusercontent.com/kmwhite40/mac-dev-setup.sh/main/install.sh | bash${NC}"
    exit 1
fi

# Check if macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ This script is only for macOS${NC}"
    echo -e "${YELLOW}   For Windows, see: packages/windows/${NC}"
    exit 1
fi

echo -e "${BLUE}ℹ️  Downloading Mac Dev Setup script...${NC}"

# Create temp directory
TEMP_DIR=$(mktemp -d)
SCRIPT_PATH="$TEMP_DIR/mac-dev-setup.sh"

# Download the script
curl -fsSL "https://raw.githubusercontent.com/kmwhite40/mac-dev-setup.sh/main/packages/macos/mac-dev-setup/scripts/mac-dev-setup.sh" -o "$SCRIPT_PATH"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}❌ Failed to download script${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Download complete${NC}"
echo ""

# Make executable
chmod +x "$SCRIPT_PATH"

# Run the script
echo -e "${BLUE}ℹ️  Starting installation...${NC}"
echo -e "${YELLOW}   You may be prompted for your password${NC}"
echo ""

"$SCRIPT_PATH"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
