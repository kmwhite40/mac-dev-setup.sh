# Mac Dev Setup - Windows Admin Guide

## Step-by-Step Guide for Windows Administrators

**Version:** 2.1.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Overview

This guide provides Windows-based administrators with step-by-step instructions to deploy the Mac Dev Setup package to macOS devices via Microsoft Intune.

**Note:** Unlike iOS apps, macOS LOB (Line-of-Business) apps require packaging before upload. This guide covers both the packaging process (requires a Mac for one-time setup) and the Intune configuration (can be done from Windows).

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Option A: Package Already Built](#option-a-package-already-built)
4. [Option B: Build Package on Mac](#option-b-build-package-on-mac)
5. [Step-by-Step: Intune Configuration (Windows)](#step-by-step-intune-configuration-windows)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Access

| Requirement | URL | Role Needed |
|-------------|-----|-------------|
| Microsoft Intune | https://intune.microsoft.com | Intune Administrator |
| Azure AD | https://portal.azure.com | User Administrator (for groups) |

### Required Files

| File | Description | How to Get |
|------|-------------|------------|
| `MacDevSetup-2.1.0.intunemac` | Intune-wrapped package | Built from Mac (see Option B) |
| `detection.sh` | Detection script | From repository `intune/` folder |

### Browser Requirements (for Intune)

- Microsoft Edge (recommended)
- Google Chrome
- Firefox

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ONE-TIME SETUP (Requires Mac):                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Scripts    │───▶│  Build PKG   │───▶│  Wrap for    │      │
│  │   from Repo  │    │  (pkgbuild)  │    │  Intune      │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                 │                │
│                                                 ▼                │
│                                     MacDevSetup-2.1.0.intunemac │
│                                                                  │
│  INTUNE CONFIGURATION (Windows):                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Upload     │───▶│  Configure   │───▶│   Assign     │      │
│  │   Package    │    │  Detection   │    │   to Groups  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                 │                │
│                                                 ▼                │
│  DEPLOYMENT TO MAC:                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Company      │───▶│   Package    │───▶│  User runs   │      │
│  │ Portal       │    │   Installs   │    │ mac-dev-setup│      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Option A: Package Already Built

If someone has already built the `.intunemac` package, you can skip directly to the Intune configuration.

### Required Files

Obtain these files from your Mac admin or the build server:

1. `MacDevSetup-2.1.0.intunemac` - The Intune-wrapped package
2. `detection.sh` - The detection script

### File Locations in Repository

```
packages/macos/mac-dev-setup/
├── intune/
│   ├── detection.sh          ← Detection script
│   ├── build-package.sh      ← Build script (for Mac)
│   └── install.sh            ← Install wrapper
└── scripts/
    └── mac-dev-setup.sh      ← Main script
```

**Skip to:** [Step-by-Step: Intune Configuration (Windows)](#step-by-step-intune-configuration-windows)

---

## Option B: Build Package on Mac

If you need to build the package, this requires a Mac. You can either:
1. Use a Mac yourself
2. Have a Mac admin build it for you
3. Use a Mac VM (if available)

### Mac Requirements

- macOS 12.0 or later
- Xcode Command Line Tools
- Admin access
- Internet connection (to download IntuneAppUtil)

### Step B.1: Install Xcode Command Line Tools

On the Mac, open Terminal and run:
```bash
xcode-select --install
```

### Step B.2: Download IntuneAppUtil

1. Go to: https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac
2. Download the latest release
3. Extract `IntuneAppUtil` to a known location

Or via Terminal:
```bash
# Create tools directory
mkdir -p ~/IntuneTools
cd ~/IntuneTools

# Download (check GitHub for latest URL)
curl -L -o IntuneAppUtil.zip "https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac/releases/download/v1.2/IntuneAppUtil-v1.2.zip"

# Extract
unzip IntuneAppUtil.zip
chmod +x IntuneAppUtil
```

### Step B.3: Clone or Download Repository

```bash
# Clone repository
git clone https://github.com/kmwhite40/mac-dev-setup.sh.git
cd mac-dev-setup.sh/packages/macos/mac-dev-setup/intune
```

### Step B.4: Build the PKG

```bash
# Make build script executable
chmod +x build-package.sh

# Run build script
./build-package.sh

# Output: MacDevSetup-2.1.0.pkg
```

**Manual build (if script fails):**
```bash
# Create package structure
mkdir -p package_root/payload
mkdir -p package_root/scripts

# Copy files
cp ../scripts/mac-dev-setup.sh package_root/payload/
cp install.sh package_root/scripts/postinstall
cp preinstall.sh package_root/scripts/preinstall

# Make scripts executable
chmod +x package_root/scripts/*

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

### Step B.5: Wrap for Intune

```bash
# Navigate to IntuneTools
cd ~/IntuneTools

# Wrap the package
./IntuneAppUtil \
  -c /path/to/MacDevSetup-2.1.0.pkg \
  -o /path/to/output \
  -i com.sbsfederal.macdevsetup \
  -n 2.1.0

# Output: MacDevSetup-2.1.0.intunemac
```

### Step B.6: Transfer Files to Windows

Transfer these files to your Windows machine:
1. `MacDevSetup-2.1.0.intunemac`
2. `detection.sh` (from the intune folder)

**Transfer methods:**
- OneDrive/SharePoint
- Network share
- USB drive
- Email (if file size allows)

---

## Step-by-Step: Intune Configuration (Windows)

### Step 1: Sign In to Intune

1. Open browser (Edge recommended)
2. Navigate to: **https://intune.microsoft.com**
3. Sign in with your Intune admin credentials
4. Complete MFA if prompted

### Step 2: Navigate to macOS Apps

**Navigation:**
```
Apps (left sidebar) > macOS > + Add
```

1. Click **Apps** in the left sidebar
2. Click **macOS** tab
3. Click **+ Add** button

### Step 3: Select App Type

1. In the "Select app type" dropdown, choose **Line-of-business app**
2. Click **Select**

### Step 4: Upload App Package

1. Click **Select app package file**
2. Click **Browse** (or the folder icon)
3. Navigate to and select: `MacDevSetup-2.1.0.intunemac`
4. Wait for upload to complete (may take a few minutes)
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
| **Information URL** | (optional) |
| **Privacy URL** | (optional) |
| **Developer** | SBS Federal IT |
| **Owner** | IT Department |
| **Notes** | Requires 20GB disk space and internet connection. User must run 'mac-dev-setup' command after Intune installation. |

Click **Next**

### Step 6: Configure Requirements

| Field | Value |
|-------|-------|
| **Minimum operating system** | macOS 10.15 (Catalina) or later |

**Note:** Leave other fields as default unless you have specific requirements.

Click **Next**

### Step 7: Configure Detection Rules

**Detection rule type:** Select **Use a custom detection script**

1. Click **Upload** next to "Script file"
2. Select the `detection.sh` file
3. Configure:

| Setting | Value |
|---------|-------|
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |

Click **Next**

### Step 8: Scope Tags (Optional)

- If using RBAC scope tags, select appropriate tags
- Otherwise, leave as default

Click **Next**

### Step 9: Assignments

**For Available Installation (Recommended):**

1. Under **Available for enrolled devices**, click **+ Add group**
2. Search for and select your Mac device/user group
3. Click **Select**

**For Required Installation (Auto-install):**

1. Under **Required**, click **+ Add group**
2. Search for and select your Mac device/user group
3. Click **Select**

**Recommended groups:**
- `Macs - Developer Devices`
- `Mac Users - Engineering`
- Or your equivalent groups

Click **Next**

### Step 10: Review + Create

1. Review all settings:
   - App name: SBS Federal Mac Dev Setup
   - Publisher: SBS Federal
   - Version: 2.1.0
   - Detection: Custom script
   - Assignments: Your selected groups

2. Click **Create**

3. Wait for the app to be created and uploaded (status bar shows progress)

### Step 11: Verify App Created

1. Navigate to: **Apps > macOS**
2. Find "SBS Federal Mac Dev Setup" in the list
3. Click on it to view properties
4. Verify all settings are correct

---

## Create Device Group (If Needed)

### Navigate to Groups

**Option 1 - From Intune:**
```
Groups (left sidebar) > + New group
```

**Option 2 - From Azure Portal:**
```
https://portal.azure.com > Azure Active Directory > Groups > + New group
```

### Create Dynamic Device Group

| Field | Value |
|-------|-------|
| Group type | Security |
| Group name | `Macs - Developer Devices` |
| Group description | `macOS devices for developers` |
| Membership type | Dynamic Device |

### Configure Dynamic Membership Rule

Click **Add dynamic query**

**Simple query builder:**
```
Property: deviceOSType
Operator: Equals
Value: MacMDM
```

**Or advanced rule (text mode):**
```
(device.deviceOSType -eq "MacMDM")
```

**For specific naming convention:**
```
(device.deviceOSType -eq "MacMDM") and (device.displayName -startsWith "MAC-")
```

Click **Save** then **Create**

---

## Verification

### Verify in Intune Console

**Check App Status:**
```
Apps > macOS > SBS Federal Mac Dev Setup > Device install status
```

| Status | Meaning |
|--------|---------|
| Installed | Successfully installed |
| Pending | Waiting for device check-in |
| Failed | Check error details |
| Not Applicable | Device not in assignment group |

**Check Device:**
```
Devices > macOS > [Device name]
```
- Verify device appears
- Check "Managed apps" section

### Verify on Mac Device

After a user installs from Company Portal:

**1. Check installation:**
```bash
ls -la "/Library/Application Support/MacDevSetup/"
```

**2. Check version file:**
```bash
cat "/Library/Application Support/MacDevSetup/version.txt"
```

**3. Run the setup:**
```bash
mac-dev-setup
```

---

## Troubleshooting

### Issue: Upload Fails

**Possible causes:**
- File too large (check network timeout settings)
- File corrupted during transfer
- Insufficient Intune permissions

**Solutions:**
1. Try uploading again
2. Re-transfer the file from Mac
3. Verify you have Intune Administrator role

### Issue: Detection Script Fails

**Possible causes:**
- Script has Windows line endings (CRLF)
- Script not uploaded correctly

**Solutions:**
1. On Mac, ensure script has Unix line endings:
   ```bash
   dos2unix detection.sh
   ```
2. Or on Windows with PowerShell:
   ```powershell
   (Get-Content detection.sh -Raw) -replace "`r`n", "`n" | Set-Content detection.sh -NoNewline
   ```
3. Re-upload the script

### Issue: App Shows "Not Applicable"

**Possible causes:**
- Device not in assignment group
- Wrong OS requirements set

**Solutions:**
1. Verify device is macOS (not iOS)
2. Check device group membership
3. Verify minimum OS is set correctly

### Issue: App Won't Install from Company Portal

**Possible causes:**
- Device not enrolled in Intune
- Company Portal outdated
- MDM profile missing

**Solutions:**
1. Verify device is enrolled:
   ```bash
   # On Mac
   profiles status -type enrollment
   ```
2. Update Company Portal
3. Re-enroll device if needed

### Issue: mac-dev-setup Command Not Found

**Cause:** Installation completed but PATH not updated

**Solution on Mac:**
```bash
# Check if wrapper exists
ls -la /usr/local/bin/mac-dev-setup

# If missing, create symlink
sudo ln -s "/Library/Application Support/MacDevSetup/mac-dev-setup.sh" /usr/local/bin/mac-dev-setup

# Or run directly
/Library/Application\ Support/MacDevSetup/mac-dev-setup.sh
```

---

## Quick Reference: Navigation Paths

| Task | Navigation Path |
|------|-----------------|
| Add macOS app | Apps > macOS > + Add |
| Check app status | Apps > macOS > [App] > Device install status |
| Create group | Groups > + New group |
| Check device | Devices > macOS > [Device name] |
| View assignments | Apps > macOS > [App] > Properties > Assignments |
| Edit app | Apps > macOS > [App] > Properties > Edit |

---

## Summary Checklist

```
WINDOWS ADMIN CHECKLIST - MAC DEV SETUP DEPLOYMENT
===================================================

PACKAGE FILES (from Mac admin or build)
[ ] MacDevSetup-2.1.0.intunemac obtained
[ ] detection.sh obtained

INTUNE CONFIGURATION
[ ] Signed into Intune admin center
[ ] App type: Line-of-business app
[ ] Package uploaded successfully
[ ] App information configured:
    [ ] Name: SBS Federal Mac Dev Setup
    [ ] Publisher: SBS Federal
    [ ] Version: 2.1.0
[ ] Requirements: macOS 10.15+
[ ] Detection script uploaded
[ ] Assigned to appropriate group(s)

DEVICE GROUP (if needed)
[ ] Group created for Mac devices
[ ] Dynamic membership rule configured

VERIFICATION
[ ] App appears in Apps > macOS list
[ ] Device install status shows correctly
[ ] Test device receives app in Company Portal
[ ] Test installation successful

Completed by: _______________ Date: _______________
```

---

## User Instructions (Share with End Users)

After the Intune installation completes, users should:

1. **Open Terminal** (Applications > Utilities > Terminal)

2. **Run the setup command:**
   ```bash
   mac-dev-setup
   ```

3. **Enter password when prompted** (for Homebrew/admin tasks)

4. **Wait for installation** (45-90 minutes first time)

5. **Done!** Desktop shortcuts and all dev tools installed.

---

## Support Contacts

| Level | Contact | When |
|-------|---------|------|
| Tier 1 | Help Desk | Basic install issues |
| Tier 2 | Intune Admin | Package/policy issues |
| Tier 3 | it@sbsfederal.com | Escalations |

---

*SBS Federal IT Department*
