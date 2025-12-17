# Intune Deployment Guide for Mac Dev Setup

This guide explains how to package and deploy the Mac Dev Setup script as an application in Microsoft Intune Company Portal.

## Package Contents

```
intune/
├── install.sh              - Main installation script (run by Intune)
├── uninstall.sh           - Uninstallation script
├── detection.sh           - Detection script to verify installation
├── preinstall.sh          - Pre-installation checks
├── postinstall.sh         - Post-installation configuration
├── package-info.json      - Package metadata
├── README-INTUNE.md       - This file
└── build-package.sh       - Script to create .pkg installer
```

## Prerequisites

### On Your Mac (for packaging)
- Xcode Command Line Tools: `xcode-select --install`
- pkgbuild and productbuild utilities (included with Xcode)
- Administrator access

### In Intune
- Microsoft Intune administrator account
- Access to Intune Admin Center
- macOS LOB app deployment permissions

## Step 1: Prepare the Package

### 1.1 Copy Required Files

```bash
# From the mac-dev-setup.sh directory
cd intune/

# Copy main script and documentation
cp ../mac-dev-setup.sh .
cp ../README.md .
cp ../QUICK_START.md .
cp ../OPERATIONS.md .
cp ../TROUBLESHOOTING.md .
cp ../INDEX.md .
cp ../PROJECT_STRUCTURE.md .
```

### 1.2 Customize Company Settings

Edit `install.sh` and update:
- Company name
- IT support email
- Update interval (if different from 4 days)

Edit `company-config.sh` section in `install.sh`:
```bash
COMPANY_NAME="Your Company Name"
IT_SUPPORT_EMAIL="itsupport@yourcompany.com"
UPDATE_INTERVAL_DAYS=4
SKIP_MACOS_UPDATES=false
```

### 1.3 Review and Test Scripts

Test locally before packaging:
```bash
# Make scripts executable
chmod +x *.sh

# Test preinstall checks
sudo ./preinstall.sh

# Test installation (will actually install)
sudo ./install.sh

# Test detection
./detection.sh

# Test uninstall
sudo ./uninstall.sh
```

## Step 2: Build the Package

### 2.1 Create Package Structure

```bash
# Create temporary package root
mkdir -p package_root/payload
mkdir -p package_root/scripts

# Copy files to payload
cp mac-dev-setup.sh package_root/payload/
cp *.md package_root/payload/

# Copy scripts
cp install.sh package_root/scripts/postinstall
cp preinstall.sh package_root/scripts/preinstall
```

### 2.2 Build the PKG

```bash
# Build component package
pkgbuild \
  --root package_root/payload \
  --scripts package_root/scripts \
  --identifier com.company.macdevsetup \
  --version 2.0.0 \
  --install-location /tmp/macdevsetup \
  MacDevSetup-component.pkg

# Build distribution package
productbuild \
  --package MacDevSetup-component.pkg \
  --identifier com.company.macdevsetup \
  --version 2.0.0 \
  MacDevSetup-2.0.0.pkg

# Clean up
rm MacDevSetup-component.pkg
rm -rf package_root
```

### 2.3 Or Use the Build Script

```bash
# Make build script executable
chmod +x build-package.sh

# Run build script
./build-package.sh

# Package will be created as: MacDevSetup-2.0.0.pkg
```

## Step 3: Create Intune Application

### 3.1 Convert PKG to INTUNEMAC

1. Download the Microsoft Intune App Wrapping Tool for macOS:
   ```bash
   # Download from Microsoft
   # https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac
   ```

2. Wrap the package:
   ```bash
   # Using IntuneAppUtil
   ./IntuneAppUtil -c MacDevSetup-2.0.0.pkg -o . -i com.company.macdevsetup -n 2.0.0

   # This creates: MacDevSetup-2.0.0.intunemac
   ```

### 3.2 Upload to Intune

1. **Sign in to Intune Admin Center:**
   - Navigate to https://intune.microsoft.com
   - Go to Apps → macOS → Add

2. **Select App Type:**
   - Choose "Line-of-business app"
   - Click "Select"

3. **Upload App Package:**
   - Click "Select app package file"
   - Upload `MacDevSetup-2.0.0.intunemac`
   - Click "OK"

4. **Configure App Information:**
   ```
   Name: Mac Dev Setup
   Description: Automated development environment setup with Docker, VS Code, Cursor, IntelliJ, and cloud tools
   Publisher: Your Company IT
   Category: Productivity
   Show as featured app: No
   Information URL: https://your-docs-url (optional)
   Privacy URL: https://your-privacy-url (optional)
   Developer: Your Company
   Owner: IT Department
   Notes: Requires internet connection and ~30GB disk space
   ```

5. **Upload Icon (optional):**
   - Upload a 512x512 PNG icon representing the app

## Step 4: Configure Detection Rules

### 4.1 Using Custom Script Detection

1. In the app configuration, go to **Detection rules**
2. Select **Use custom detection script**
3. Upload `detection.sh`
4. Script output: Standard output
5. Click "OK"

### 4.2 Or Use File-Based Detection

Alternatively, detect by checking for the version file:
```
Detection rule type: File
Path: /Library/Application Support/MacDevSetup
File or folder: version.txt
Detection method: File or folder exists
```

## Step 5: Configure Requirements

Set minimum requirements:
```
Operating system: macOS 10.15 or later
Architecture: x64, ARM64
Disk space required: 30 GB
Physical memory required: 4 GB (recommended)
Number of processors required: 2 (recommended)
CPU speed required: Not configured
```

## Step 6: Configure Installation Settings

```
Install command: /bin/bash /tmp/macdevsetup/install.sh
Uninstall command: /bin/bash /Library/Application\ Support/MacDevSetup/uninstall.sh
Install behavior: System
Device restart behavior: App install may force device restart
Return codes:
  - 0 = Success
  - 1 = Failed
```

## Step 7: Assign to Groups

### 7.1 Available for Enrolled Devices
For optional installation via Company Portal:
1. Click **Assignments**
2. Under **Available for enrolled devices**, click **Add group**
3. Select target user or device groups
4. Set filter (optional)
5. Click "OK"

### 7.2 Required Installation
For mandatory deployment:
1. Under **Required**, click **Add group**
2. Select target groups
3. Set installation deadline
4. Click "OK"

## Step 8: Deploy and Monitor

### 8.1 Save and Deploy
1. Review all settings
2. Click **Create**
3. Monitor deployment status in Intune

### 8.2 Monitor Installation

View installation status:
1. Go to Apps → macOS apps → Mac Dev Setup
2. Click **Device install status**
3. View success/failure/in-progress installations

### 8.3 View Logs

**On client devices:**
```bash
# Intune installation logs
cat /Library/Logs/MacDevSetup/intune-install.log

# Preinstall checks
cat /Library/Logs/MacDevSetup/preinstall.log

# Postinstall tasks
cat /Library/Logs/MacDevSetup/postinstall.log

# User execution logs
cat ~/.mac-dev-setup.log
```

## User Experience

### Company Portal Installation

1. User opens Company Portal on Mac
2. Searches for "Mac Dev Setup"
3. Clicks "Install"
4. Company Portal downloads and installs package
5. User receives notification when complete
6. User opens Terminal and runs: `mac-dev-setup`

### First Run Experience

```bash
# User runs the command
mac-dev-setup

# Script performs:
1. Checks for Homebrew (installs if needed)
2. Updates macOS if 4+ days since last update
3. Installs all applications
4. Creates desktop shortcuts
5. Shows next steps
```

## Troubleshooting

### Installation Fails

**Check logs:**
```bash
cat /Library/Logs/MacDevSetup/intune-install.log
```

**Common issues:**
- Insufficient disk space → Free up 30GB
- No internet connection → Connect to network
- Permissions issue → Verify Intune has admin rights

### Detection Fails

**Verify installation:**
```bash
# Check if files exist
ls -la "/Library/Application Support/MacDevSetup/"

# Manually run detection
/Library/Application\ Support/MacDevSetup/detection.sh
echo $?  # Should return 0
```

### Applications Not Installing

**Check Homebrew:**
```bash
# Verify Homebrew is installed
which brew

# Check Homebrew logs
cat ~/.mac-dev-setup.log | grep "Failed"
```

## Updating the Package

### Version 2.1 Update Process

1. Update version in `package-info.json`
2. Update version in `detection.sh` (MIN_VERSION)
3. Rebuild package
4. Upload new version to Intune
5. Intune will detect version change and offer update

### Force Reinstall

If users need to force reinstall:
```bash
# Remove version file
sudo rm "/Library/Application Support/MacDevSetup/version.txt"

# Intune will detect as not installed and reinstall
```

## Customization Options

### Modify Application List

Edit `mac-dev-setup.sh` to add/remove applications:
```bash
# Add new app
install_cask "new-app-name"

# Remove app (comment out)
# install_cask "unwanted-app"
```

### Modify Update Frequency

Edit in `install.sh` → `company-config.sh`:
```bash
UPDATE_INTERVAL_DAYS=7  # Change to weekly
```

### Disable macOS System Updates

For corporate environments with separate patch management:
```bash
SKIP_MACOS_UPDATES=true
```

Then modify `mac-dev-setup.sh` to check this setting.

### Add Corporate Branding

Edit notification in `postinstall.sh`:
```bash
display notification "Message" with title "Your Company - Dev Setup"
```

## Security Considerations

### Code Signing (Recommended)

Sign the package for enhanced security:
```bash
productsign \
  --sign "Developer ID Installer: Your Company" \
  MacDevSetup-2.0.0.pkg \
  MacDevSetup-2.0.0-signed.pkg
```

### Notarization (Recommended)

Notarize with Apple for Gatekeeper:
```bash
xcrun notarytool submit MacDevSetup-2.0.0-signed.pkg \
  --apple-id your@email.com \
  --team-id TEAMID \
  --password app-specific-password
```

## Support

### End User Support

Users can:
1. View documentation: `/Library/Application Support/MacDevSetup/`
2. Check logs: `~/.mac-dev-setup.log`
3. Run troubleshooting: See `TROUBLESHOOTING.md`
4. Contact IT: Email configured in company-config.sh

### IT Support

Admins can:
1. View system logs: `/Library/Logs/MacDevSetup/`
2. Check installation: Run `detection.sh`
3. Force reinstall: Remove version.txt file
4. Review Intune console for deployment status

## Compliance and Reporting

### Track Installation Status

Use Intune reports to track:
- Installation success rate
- Failed installations
- Devices not yet installed
- Version compliance

### Create Custom Report

In Intune:
1. Go to Reports → Device compliance
2. Create custom report filtering for Mac Dev Setup
3. Schedule automated reports

---

## Quick Reference

### Package Build Command
```bash
./build-package.sh
```

### Upload to Intune
1. Apps → macOS → Add
2. Upload .intunemac file
3. Configure detection, requirements, assignments
4. Save and deploy

### Monitor Deployment
```bash
# On client
cat /Library/Logs/MacDevSetup/intune-install.log

# In Intune
Apps → Mac Dev Setup → Device install status
```

### User Command
```bash
mac-dev-setup
```

---

**Last Updated:** 2025-12-17
**Package Version:** 2.0.0
**Intune Compatibility:** Tested with Intune on macOS 10.15+
