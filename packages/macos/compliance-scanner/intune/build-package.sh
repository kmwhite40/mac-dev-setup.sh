#!/bin/bash

################################################################################
# Build Script for NIST 800-53 Compliance Scanner Intune Package
# Creates a .pkg installer ready for Intune deployment
################################################################################

set -e

# Configuration
PACKAGE_NAME="ComplianceScanner"
VERSION="1.0.0"
IDENTIFIER="com.sbsfederal.compliancescanner"
INSTALL_LOCATION="/tmp/compliancescanner"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}NIST 800-53 Compliance Scanner - Package Builder${NC}"
echo -e "${BLUE}=========================================${NC}"

# Check if we're in the intune directory
if [ ! -f "install.sh" ]; then
    echo -e "${RED}Error: Must run from intune/ directory${NC}"
    exit 1
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/
rm -f ${PACKAGE_NAME}-*.pkg

# Create build directories
echo "Creating build structure..."
mkdir -p build/payload
mkdir -p build/scripts

# Copy main script
echo "Copying files to package..."
if [ -f "../nist-800-53-scanner.sh" ]; then
    cp ../nist-800-53-scanner.sh build/payload/
    echo "  ✓ Copied nist-800-53-scanner.sh"
else
    echo -e "${RED}Error: nist-800-53-scanner.sh not found in parent directory${NC}"
    exit 1
fi

# Copy installation scripts
echo "Copying installation scripts..."
cp install.sh build/scripts/postinstall
cp preinstall.sh build/scripts/preinstall
chmod +x build/scripts/*

# Validate scripts
echo "Validating scripts..."
bash -n build/scripts/postinstall || { echo -e "${RED}Syntax error in install.sh${NC}"; exit 1; }
bash -n build/scripts/preinstall || { echo -e "${RED}Syntax error in preinstall.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ All scripts validated${NC}"

# Set permissions
echo "Setting permissions..."
chmod 755 build/payload/*
chmod +x build/payload/nist-800-53-scanner.sh

# Build component package
echo "Building component package..."
pkgbuild \
  --root build/payload \
  --scripts build/scripts \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  --install-location "$INSTALL_LOCATION" \
  build/${PACKAGE_NAME}-component.pkg

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Component package created${NC}"
else
    echo -e "${RED}  ✗ Failed to create component package${NC}"
    exit 1
fi

# Create distribution XML
cat > build/distribution.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>NIST 800-53 Compliance Scanner</title>
    <organization>com.sbsfederal</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <pkg-ref id="$IDENTIFIER"/>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">
        ${PACKAGE_NAME}-component.pkg
    </pkg-ref>
</installer-gui-script>
EOF

# Build final distribution package
echo "Building distribution package..."
productbuild \
  --distribution build/distribution.xml \
  --package-path build \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  ${PACKAGE_NAME}-${VERSION}.pkg

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Distribution package created${NC}"
else
    echo -e "${RED}  ✗ Failed to create distribution package${NC}"
    exit 1
fi

# Get package size
PKG_SIZE=$(du -h ${PACKAGE_NAME}-${VERSION}.pkg | cut -f1)

# Display package info
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Package Build Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo "Package Name: ${PACKAGE_NAME}-${VERSION}.pkg"
echo "Package Size: $PKG_SIZE"
echo "Identifier: $IDENTIFIER"
echo "Version: $VERSION"
echo ""
echo "Next Steps:"
echo "1. Test the package locally:"
echo "   sudo installer -pkg ${PACKAGE_NAME}-${VERSION}.pkg -target /"
echo ""
echo "2. Convert to .intunemac format:"
echo "   ./IntuneAppUtil -c ${PACKAGE_NAME}-${VERSION}.pkg -o . -i $IDENTIFIER -n $VERSION"
echo ""
echo "3. Upload to Intune:"
echo "   - Sign in to https://intune.microsoft.com"
echo "   - Apps → macOS → Add → Line-of-business app"
echo "   - Upload the .intunemac file"
echo ""
echo "4. Configure and assign to groups"
echo ""
echo -e "${GREEN}=========================================${NC}"

exit 0
