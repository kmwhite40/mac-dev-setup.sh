# Mac Dev Setup - Intune Admin Guide

## SBS Federal IT Administration Guide

**Version:** 2.1.0
**Last Updated:** 2025-01-30
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Package Contents](#package-contents)
4. [Building the Package](#building-the-package)
5. [Uploading to Intune](#uploading-to-intune)
6. [Configuring the App](#configuring-the-app)
7. [Assignment and Deployment](#assignment-and-deployment)
8. [End User Experience](#end-user-experience)
9. [Monitoring Deployment](#monitoring-deployment)
10. [Troubleshooting](#troubleshooting)
11. [FAQ](#faq)

> **Windows Admin?** See [WINDOWS-ADMIN-GUIDE.md](WINDOWS-ADMIN-GUIDE.md) for step-by-step browser-based instructions.

---

## Overview

The SBS Federal Mac Dev Setup automates the deployment of a complete development environment to macOS endpoints via Microsoft Intune Company Portal.

### Applications Installed

#### GUI Applications (14)
| Application | Description |
|-------------|-------------|
| Docker Desktop | Container platform |
| Podman Desktop | Container management |
| iTerm2 | Terminal emulator |
| Visual Studio Code | Code editor |
| Cursor | AI-powered code editor |
| IntelliJ IDEA CE | Java IDE |
| Obsidian | Knowledge management |
| Postman | API testing |
| pgAdmin4 | PostgreSQL management |
| TablePlus | Database client |
| DBeaver | Universal database tool |
| MongoDB Compass | MongoDB GUI |
| GitHub Desktop | Git GUI client |

#### CLI Tools (21)
| Tool | Description |
|------|-------------|
| git, gh, glab | Version control & GitHub/GitLab CLIs |
| maven | Java build tool |
| node | JavaScript runtime |
| python | Python interpreter |
| openjdk | Java Development Kit |
| go | Go programming language |
| dotnet | .NET SDK |
| kubectl, helm, k9s | Kubernetes tools |
| awscli | AWS command line |
| azure-cli | Azure command line |
| google-cloud-sdk | GCP command line |
| terraform | Infrastructure as Code |
| ansible | Configuration management |
| curl, httpie, k6 | HTTP tools |
| jq | JSON processor |
| coder | Remote development |

### Features
- Automatic Homebrew installation
- macOS system updates every 4 days
- Xcode Command Line Tools installation
- Rosetta 2 for Apple Silicon
- Desktop shortcuts creation
- Comprehensive logging

---

## Prerequisites

### Admin Requirements
- Microsoft Intune Administrator role
- Access to Microsoft Endpoint Manager admin center
- Mac with Xcode Command Line Tools (for packaging)
- Apple Developer account (optional, for signing)

### Endpoint Requirements
- macOS 10.14 (Mojave) or later
- macOS 10.15+ recommended
- Apple Silicon (M1/M2/M3) or Intel processor
- 20 GB free disk space minimum
- Internet connectivity
- User account with admin privileges

### Tools Required for Packaging
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Download Intune App Wrapping Tool
# https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac
```

---

## Package Contents

```
mac-dev-setup/
├── scripts/
│   └── mac-dev-setup.sh          # Main installer script (v2.1.0)
├── intune/
│   ├── install.sh                 # Intune installation wrapper
│   ├── uninstall.sh               # Uninstallation script
│   ├── detection.sh               # Detection script
│   ├── preinstall.sh              # Pre-installation checks
│   ├── postinstall.sh             # Post-installation tasks
│   ├── build-package.sh           # Package builder
│   ├── package-info.json          # Package metadata
│   ├── README-INTUNE.md           # Detailed Intune guide
│   ├── INTUNE-QUICK-START.md      # Quick start guide
│   └── DEPLOYMENT-CHECKLIST.md    # Deployment checklist
└── docs/
    └── INTUNE-ADMIN-GUIDE.md      # This guide
```

---

## Building the Package

### Step 1: Prepare the Environment

```bash
# Navigate to the intune folder
cd packages/macos/mac-dev-setup/intune/

# Make scripts executable
chmod +x *.sh
```

### Step 2: Customize Company Settings (Optional)

Edit `install.sh` to customize:
```bash
# Company Configuration
COMPANY_NAME="SBS Federal"
IT_SUPPORT_EMAIL="it@sbsfederal.com"
UPDATE_INTERVAL_DAYS=4
```

### Step 3: Build the PKG

```bash
# Run the build script
./build-package.sh

# Output: MacDevSetup-2.1.0.pkg
```

**Manual build (if needed):**
```bash
# Create package structure
mkdir -p package_root/payload
mkdir -p package_root/scripts

# Copy files
cp ../scripts/mac-dev-setup.sh package_root/payload/
cp install.sh package_root/scripts/postinstall
cp preinstall.sh package_root/scripts/preinstall

# Build component package
pkgbuild \
  --root package_root/payload \
  --scripts package_root/scripts \
  --identifier com.sbsfederal.macdevsetup \
  --version 2.1.0 \
  --install-location /tmp/macdevsetup \
  MacDevSetup-component.pkg

# Build distribution package
productbuild \
  --package MacDevSetup-component.pkg \
  --identifier com.sbsfederal.macdevsetup \
  --version 2.1.0 \
  MacDevSetup-2.1.0.pkg

# Clean up
rm MacDevSetup-component.pkg
rm -rf package_root
```

### Step 4: Convert for Intune

```bash
# Download IntuneAppUtil from:
# https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac

# Convert PKG to INTUNEMAC
./IntuneAppUtil \
  -c MacDevSetup-2.1.0.pkg \
  -o . \
  -i com.sbsfederal.macdevsetup \
  -n 2.1.0

# Output: MacDevSetup-2.1.0.intunemac
```

---

## Uploading to Intune

### Step 1: Sign In to Intune Admin Center

1. Open your browser (Microsoft Edge recommended)
2. Navigate to: **https://intune.microsoft.com**
3. Sign in with your Intune administrator credentials
4. Complete MFA authentication if prompted

### Step 2: Navigate to macOS Apps

**Navigation Path:**
```
Apps (left sidebar) → macOS → + Add
```

1. Click **Apps** in the left navigation sidebar
2. Click the **macOS** tab at the top
3. Click the **+ Add** button

### Step 3: Select App Type

1. In the "Select app type" panel that appears on the right:
   - Click the dropdown menu
   - Select **Line-of-business app**
2. Click **Select** at the bottom

### Step 4: Upload App Package File

1. Click **Select app package file**
2. In the file picker dialog:
   - Click **Browse** (or the folder icon)
   - Navigate to where you saved the `.intunemac` file
   - Select: `MacDevSetup-2.1.0.intunemac`
3. Wait for the file to upload (progress bar shows status)
4. Verify the file info shows:
   - Name: MacDevSetup-2.1.0
   - Size: (varies, typically 10-50 KB)
5. Click **OK**

### Step 5: Configure App Information

Fill in the following fields:

| Field | Value |
|-------|-------|
| **Name** | SBS Federal Mac Dev Setup |
| **Description** | Automated development environment setup for macOS. Installs Docker, VS Code, Cursor, IntelliJ, Kubernetes tools, cloud CLIs, and more. After installation, open Terminal and run: mac-dev-setup |
| **Publisher** | SBS Federal |
| **App Version** | 2.1.0 |
| **Category** | Developer Tools |
| **Information URL** | *(optional - leave blank or enter docs URL)* |
| **Privacy URL** | *(optional)* |
| **Developer** | SBS Federal IT |
| **Owner** | IT Department |
| **Notes** | Requires 20GB free disk space and internet connection. User must run 'mac-dev-setup' command in Terminal after Intune installation completes. |

Click **Next**

### Step 6: Configure Requirements

| Field | Value |
|-------|-------|
| **Minimum operating system** | macOS 10.15 (Catalina) or later |

**Note:** Leave other requirement fields as default unless you have specific needs.

Click **Next**

### Step 7: Configure Detection Rules

**Detection rule type:** Select **Use a custom detection script**

1. Click **Upload** (or the folder icon) next to "Script file"
2. Navigate to and select the `detection.sh` file from the intune folder
3. Configure the following settings:

| Setting | Value |
|---------|-------|
| Run script as 32-bit process on 64-bit clients | **No** |
| Enforce script signature check | **No** |

**Alternative: File-Based Detection** *(if not using script)*

If you prefer file-based detection instead of a script:

| Setting | Value |
|---------|-------|
| Detection rule type | File |
| Path | `/Library/Application Support/MacDevSetup` |
| File or folder | `version.txt` |
| Detection method | File or folder exists |

Click **Next**

### Step 8: Scope Tags (Optional)

- If your organization uses RBAC scope tags, select the appropriate tags
- If not using scope tags, leave as default

Click **Next**

### Step 9: Configure Assignments

**For Available Installation (Recommended for Developer Tools):**

1. Under **Available for enrolled devices**, click **+ Add group**
2. In the search box, type your device/user group name
3. Select the appropriate group(s):
   - Example: `Macs - Developer Devices`
   - Example: `Mac Users - Engineering`
4. Click **Select**

**For Required Installation (Auto-install):**

1. Under **Required**, click **+ Add group**
2. Search for and select your target group(s)
3. Click **Select**

**Recommended Groups:**
| Group Purpose | Suggested Name |
|---------------|----------------|
| Developer Macs | `Macs - Developer Devices` |
| Engineering Users | `Mac Users - Engineering` |
| IT Test Devices | `Macs - IT Test Group` |

Click **Next**

### Step 10: Review + Create

1. **Review all settings carefully:**
   - App name: SBS Federal Mac Dev Setup
   - Publisher: SBS Federal
   - Version: 2.1.0
   - Detection: Custom script (or File-based)
   - Assignments: Your selected groups

2. Click **Create**

3. **Wait for deployment:**
   - Progress bar shows upload status
   - May take 1-5 minutes depending on file size
   - Status changes to "Created" when complete

4. **Verify the app was created:**
   - Navigate to: **Apps** → **macOS**
   - Find "SBS Federal Mac Dev Setup" in the app list
   - Click on it to view properties

### Step 11: Verify App Configuration

After creation, click on the app to verify:

1. **Properties tab:**
   - Confirm all app information is correct
   - Version shows 2.1.0

2. **Assignments tab:**
   - Verify correct groups are assigned
   - Check assignment type (Available vs Required)

3. **Device install status:**
   - Initially shows "Pending" for assigned devices
   - Updates as devices check in and install

---

## Configuring the App

### Installation Behavior

The package installs in two phases:

**Phase 1: Intune Installation (Automatic)**
- Creates `/Library/Application Support/MacDevSetup/`
- Copies main script and documentation
- Creates `/usr/local/bin/mac-dev-setup` wrapper
- Creates version file for detection
- Writes to `/Library/Logs/MacDevSetup/`

**Phase 2: User Execution (Manual)**
- User opens Terminal and runs `mac-dev-setup`
- Script checks for Homebrew (installs if needed)
- Checks for macOS updates (applies if 4+ days old)
- Installs all applications via Homebrew
- Creates desktop shortcuts

### Customization Options

**Change Update Frequency:**
```bash
# In install.sh, modify:
UPDATE_INTERVAL_DAYS=7  # Weekly instead of 4 days
```

**Skip macOS Updates:**
```bash
# In install.sh, modify:
SKIP_MACOS_UPDATES=true
```

**Modify Application List:**
Edit `mac-dev-setup.sh` to add/remove applications:
```bash
# Add new cask
install_cask "new-app-name"

# Add new formula
install_formula "new-tool"

# Remove (comment out)
# install_cask "unwanted-app"
```

---

## Assignment and Deployment

### Deployment Options

#### Option 1: Available for Enrolled Devices (Recommended)
- Appears in Company Portal for user self-service
- User initiates installation
- Best for: Developer teams, gradual rollout

#### Option 2: Required Deployment
- Automatically installs on assigned devices
- No user interaction for Intune phase
- User still must run `mac-dev-setup` manually
- Best for: New device provisioning

### Creating Assignments

1. In the app properties, go to **Assignments**
2. Click **+ Add group**

**For Available Deployment:**
| Setting | Value |
|---------|-------|
| Assignment type | Available for enrolled devices |
| Group | Select target device/user group |
| End user notifications | Show all toast notifications |

**For Required Deployment:**
| Setting | Value |
|---------|-------|
| Assignment type | Required |
| Group | Select target device/user group |
| End user notifications | Show all toast notifications |
| Installation deadline | (set appropriate deadline) |

### Recommended Deployment Strategy

**Phase 1: Pilot (Week 1)**
- Deploy to IT test group (5-10 users)
- Monitor for issues
- Verify all apps install correctly
- Test on both Intel and Apple Silicon Macs

**Phase 2: Early Adopters (Week 2-3)**
- Deploy to developer volunteers (50-100 users)
- Gather feedback
- Address any issues
- Refine documentation

**Phase 3: General Availability (Week 4+)**
- Make available in Company Portal for all developers
- Send announcement with instructions
- Monitor support tickets

---

## End User Experience

### Company Portal Installation

1. User opens **Company Portal** on Mac
2. Searches for "**Mac Dev Setup**"
3. Clicks "**Install**"
4. Company Portal downloads and installs package
5. User receives notification when complete

### Running the Setup

After Company Portal installation:

1. User opens **Terminal**
2. Runs: `mac-dev-setup`
3. Script prompts for password (for Homebrew/updates)
4. Installation takes 45-90 minutes (first time)
5. Desktop shortcuts are created
6. User receives completion message

### What Users See

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║       SBS Federal - Mac Dev Environment Setup              ║
║                                                            ║
║       Automated Developer Toolchain Installer              ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Checking prerequisites...
✅ macOS version: 14.2.1 (Sonoma)
✅ Xcode Command Line Tools installed
✅ Rosetta 2 installed (Apple Silicon)
✅ Disk space: 45.2 GB available
✅ Internet connectivity confirmed

Installing Homebrew...
✅ Homebrew installed successfully

Installing GUI Applications...
✅ Docker Desktop installed
✅ Visual Studio Code installed
✅ Cursor installed
...

Creating Desktop Shortcuts...
✅ Created desktop shortcut for Docker
✅ Created desktop shortcut for Visual Studio Code
...

Installation complete!
```

---

## Monitoring Deployment

### Viewing Installation Status

1. Go to **Apps** > **Monitor** > **App install status**
2. Select "SBS Federal Mac Dev Setup"
3. Review:
   - Device install status
   - User install status
   - Installation failures

### Status Codes

| Status | Meaning |
|--------|---------|
| Installed | Phase 1 (Intune) complete |
| Pending | Waiting for device sync |
| Failed | Installation error |
| Not Applicable | Device doesn't meet requirements |

### Accessing Logs

**On the Mac device:**
```bash
# Intune installation logs
cat /Library/Logs/MacDevSetup/intune-install.log

# Pre-install check logs
cat /Library/Logs/MacDevSetup/preinstall.log

# Post-install logs
cat /Library/Logs/MacDevSetup/postinstall.log

# User execution logs
cat ~/.mac-dev-setup.log
```

**In Intune:**
1. Go to **Devices** > **macOS devices**
2. Select the device
3. View installation history

---

## Troubleshooting

### Common Issues

#### Issue: Intune Installation Fails
**Cause:** Preinstall checks failed
**Solution:**
```bash
# Check preinstall log
cat /Library/Logs/MacDevSetup/preinstall.log

# Common causes:
# - Insufficient disk space
# - macOS version too old
# - Missing admin rights
```

#### Issue: Detection Script Returns "Not Installed"
**Cause:** Version file missing or version mismatch
**Solution:**
```bash
# Check version file
cat "/Library/Application Support/MacDevSetup/version.txt"

# If missing, reinstall or create manually
echo "2.1.0" | sudo tee "/Library/Application Support/MacDevSetup/version.txt"
```

#### Issue: `mac-dev-setup` Command Not Found
**Cause:** PATH not updated or wrapper not created
**Solution:**
```bash
# Check if wrapper exists
ls -la /usr/local/bin/mac-dev-setup

# If missing, create manually
sudo ln -s "/Library/Application Support/MacDevSetup/mac-dev-setup.sh" /usr/local/bin/mac-dev-setup

# Or add to PATH
export PATH="/Library/Application Support/MacDevSetup:$PATH"
```

#### Issue: Homebrew Installation Fails
**Cause:** Network issues or permissions
**Solution:**
```bash
# Check if Homebrew is accessible
which brew

# Reinstall Homebrew manually
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon, ensure PATH includes:
export PATH="/opt/homebrew/bin:$PATH"
```

#### Issue: Applications Don't Install
**Cause:** User hasn't run `mac-dev-setup` after Intune install
**Solution:**
- Remind user to open Terminal and run `mac-dev-setup`
- Check user execution log: `~/.mac-dev-setup.log`

#### Issue: Desktop Shortcuts Not Created
**Cause:** Applications not yet installed or Desktop folder missing
**Solution:**
```bash
# Run the script again
mac-dev-setup

# Or create shortcuts manually
ln -s "/Applications/Visual Studio Code.app" ~/Desktop/"Visual Studio Code"
```

### Diagnostic Commands

```bash
# Check if Intune package installed
ls -la "/Library/Application Support/MacDevSetup/"

# Check detection
/Library/Application\ Support/MacDevSetup/../intune/detection.sh
echo $?  # 0 = installed

# Check Homebrew
which brew
brew doctor

# Check installed casks
brew list --cask

# Check installed formulae
brew list --formula

# View errors in log
grep -i "error\|fail\|❌" ~/.mac-dev-setup.log
```

---

## FAQ

### Q: How long does the full installation take?
**A:**
- Intune installation: 1-2 minutes
- User runs `mac-dev-setup`: 45-90 minutes (first time)
- Subsequent runs: 5-15 minutes (updates only)

### Q: Does this work on Apple Silicon Macs?
**A:** Yes, the script automatically detects Apple Silicon and installs Rosetta 2 if needed.

### Q: Can users cancel the installation?
**A:**
- Intune phase: No (for Required deployments)
- User phase: Yes, they can close Terminal (resume anytime)

### Q: What if Homebrew is already installed?
**A:** The script detects existing Homebrew and skips installation.

### Q: How do I update the package?
**A:**
1. Update version in `package-info.json` and `detection.sh`
2. Rebuild the package
3. Upload new version to Intune
4. Use supersedence to replace old version

### Q: How do I uninstall?
**A:**
```bash
sudo /Library/Application\ Support/MacDevSetup/uninstall.sh
```
Note: This removes the package but NOT the installed applications.

### Q: What network access is required?
**A:**
- github.com (Homebrew)
- brew.sh (Homebrew packages)
- swscan.apple.com (macOS updates)
- Various CDNs for application downloads

### Q: Can I customize the application list?
**A:** Yes, edit `mac-dev-setup.sh` before building the package.

---

## Support

For assistance with deployment issues:

- **Email:** it@sbsfederal.com
- **Documentation:** See `intune/` folder for detailed guides
- **Logs:** Always include logs when reporting issues

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.1.0 | 2025-01-05 | Added prerequisites, Xcode CLT, Rosetta 2 |
| 2.0.0 | 2024-12-17 | Major rewrite, Intune package support |
| 1.0.0 | 2024-12-01 | Initial release |

---

## Quick Reference Card

| Item | Value |
|------|-------|
| Package Name | SBS Federal Mac Dev Setup |
| Version | 2.1.0 |
| Identifier | com.sbsfederal.macdevsetup |
| Min OS | macOS 10.15 |
| Disk Space | 20 GB |
| Install Location | /Library/Application Support/MacDevSetup |
| User Command | `mac-dev-setup` |
| Logs | /Library/Logs/MacDevSetup/, ~/.mac-dev-setup.log |
| Detection | /Library/Application Support/MacDevSetup/version.txt |

---

*SBS Federal IT Department*
*Confidential - Internal Use Only*
