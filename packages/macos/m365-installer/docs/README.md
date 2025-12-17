# Microsoft 365 Installer for macOS

Automated installer for Microsoft 365 applications on macOS with comprehensive logging, error handling, and Intune deployment support.

---

## 🎯 Overview

The Microsoft 365 Installer is an enterprise-grade deployment tool designed for **SBS Federal** that automatically downloads and installs Microsoft 365 applications on macOS endpoints.

**Key Features:**
- ✅ Automatic download from Microsoft CDN
- ✅ Installs complete Office Suite (Word, Excel, PowerPoint, Outlook, OneNote)
- ✅ Installs Microsoft Teams, OneDrive, Edge, Company Portal
- ✅ Smart detection of existing installations
- ✅ Desktop shortcuts creation
- ✅ Automatic update configuration
- ✅ Comprehensive logging
- ✅ Intune-ready deployment

---

## 📦 Applications Installed

### Core Microsoft 365 Suite
- **Microsoft Word** - Word processing
- **Microsoft Excel** - Spreadsheets
- **Microsoft PowerPoint** - Presentations
- **Microsoft Outlook** - Email and calendar
- **Microsoft OneNote** - Note-taking

### Additional Applications
- **Microsoft Teams** - Collaboration and meetings
- **Microsoft OneDrive** - Cloud storage and file sync
- **Microsoft Edge** - Web browser
- **Company Portal** - Intune/MDM management

### Optional (App Store)
- **Microsoft Remote Desktop** - Remote connections
- **Microsoft To Do** - Task management

### Optional (MDM)
- **Microsoft Defender** - Endpoint protection

---

## 🚀 Quick Start

### Individual Use

```bash
# Make executable
chmod +x m365-installer.sh

# Run installer
./m365-installer.sh
```

### After Intune Installation

```bash
# Run via command line
m365-install

# Or use desktop launcher
open "/Users/Shared/Install Microsoft 365.command"
```

**Installation Time:** 20-45 minutes (depending on internet speed)

---

## 📁 File Locations

### User Installation
```
~/.m365-installer/
  ├── installer.log                 # Installation log
  └── downloads/                    # Temporary download directory (auto-cleaned)
```

### Intune Installation
```
/Library/Application Support/M365Installer/
  └── m365-installer.sh             # Main installer script

/Library/Logs/M365Installer/
  ├── intune-install.log            # Intune installation log
  ├── preinstall.log                # Pre-install checks
  └── postinstall.log               # Post-install tasks

/Users/Shared/
  └── Install Microsoft 365.command # Desktop launcher

/usr/local/bin/
  └── m365-install                  # Command wrapper

/Applications/
  ├── Microsoft Word.app
  ├── Microsoft Excel.app
  ├── Microsoft PowerPoint.app
  ├── Microsoft Outlook.app
  ├── Microsoft OneNote.app
  ├── Microsoft Teams.app
  ├── OneDrive.app
  ├── Microsoft Edge.app
  └── Company Portal.app
```

---

## 🔧 How It Works

### Installation Process

1. **Pre-flight Checks**
   - Verifies macOS version (10.14+)
   - Checks available disk space (10GB+)
   - Tests internet connectivity
   - Detects system architecture

2. **Download Applications**
   - Downloads from official Microsoft CDN
   - Shows progress for each download
   - Validates downloaded packages

3. **Installation**
   - Installs Microsoft 365 Suite (Office apps)
   - Installs Teams, OneDrive, Edge
   - Installs Company Portal
   - Skips already installed applications

4. **Post-Installation**
   - Creates desktop shortcuts
   - Configures automatic updates
   - Displays sign-in instructions
   - Cleans up temporary files

### Smart Features

**Existing Installation Detection:**
- Checks if apps are already installed
- Shows current version
- Skips reinstallation

**Error Handling:**
- Individual app failures don't stop installation
- Detailed error logging
- Recovery recommendations

**Progress Tracking:**
- Color-coded status messages
- Installation summary
- Success/failure counts

---

## 📊 Download Sources

All applications are downloaded directly from Microsoft's official CDN:

| Application | Download URL |
|------------|--------------|
| Office Suite | https://go.microsoft.com/fwlink/?linkid=525133 |
| Teams | https://go.microsoft.com/fwlink/?linkid=869428 |
| OneDrive | https://go.microsoft.com/fwlink/?linkid=823060 |
| Edge | https://go.microsoft.com/fwlink/?linkid=2093504 |
| Company Portal | https://go.microsoft.com/fwlink/?linkid=853070 |

**Note:** These are Microsoft's official universal download links that always provide the latest version.

---

## 🔐 Post-Installation Setup

### 1. Sign In to Microsoft 365

```bash
# Open any Office app (Word, Excel, PowerPoint, Outlook)
1. Click "Sign In" button
2. Enter SBS Federal credentials: username@sbsfederal.com
3. Follow authentication prompts
4. Choose "Keep me signed in" (optional)
```

### 2. Configure OneDrive

```bash
# Open OneDrive
1. Launch OneDrive from Applications or Desktop
2. Click "Sign In"
3. Enter SBS Federal credentials
4. Choose folders to sync
5. Select sync location (default: ~/OneDrive - SBS Federal)
```

### 3. Set Up Microsoft Teams

```bash
# Open Microsoft Teams
1. Launch Teams from Applications or Desktop
2. Sign in with SBS Federal credentials
3. Configure notifications preferences
4. Set up audio/video devices
5. Join your organization's teams
```

### 4. Configure Microsoft Edge

```bash
# Open Microsoft Edge
1. Launch Edge from Applications or Desktop
2. Sign in with SBS Federal account (optional)
3. Sync favorites, passwords, settings
4. Set as default browser (optional)
```

### 5. Enroll in Company Portal

```bash
# Open Company Portal
1. Launch Company Portal
2. Sign in with SBS Federal credentials
3. Enroll device (if required)
4. Install additional corporate apps
```

---

## 🔧 Configuration

### Automatic Updates

The installer automatically configures Microsoft AutoUpdate (MAU):

```bash
# Check for updates manually
1. Open any Office app
2. Go to Help → Check for Updates
3. Microsoft AutoUpdate will launch
4. Install available updates
```

**Automatic Update Settings:**
- Enabled by default
- Checks daily
- Downloads automatically
- Prompts before installing

### Desktop Shortcuts

Shortcuts created for:
- Microsoft Word
- Microsoft Excel
- Microsoft PowerPoint
- Microsoft Outlook
- Microsoft Teams
- Microsoft Edge
- OneDrive

**To remove shortcuts:**
```bash
rm ~/Desktop/Microsoft*
rm ~/Desktop/OneDrive
```

---

## 🚀 Intune Deployment

### Build Package

```bash
cd intune/
./build-package.sh
```

### Convert for Intune

```bash
./IntuneAppUtil -c M365Installer-1.0.0.pkg -o . -i com.sbsfederal.m365installer -n 1.0.0
```

### Upload to Intune

1. Go to https://intune.microsoft.com
2. Apps → macOS → Add → Line-of-business app
3. Upload `M365Installer-1.0.0.intunemac`
4. Configure:
   - Name: Microsoft 365 Installer
   - Publisher: SBS Federal IT
   - Category: Productivity
   - Show in Company Portal: Yes
5. Detection: Upload `detection.sh`
6. Assign to groups

### User Experience

1. User opens Company Portal
2. Searches for "Microsoft 365 Installer"
3. Clicks Install (10 seconds)
4. Receives notification
5. Opens Terminal, runs: `m365-install`
6. Apps install automatically (20-45 min)
7. Desktop shortcuts appear
8. User signs in to M365 apps

---

## 📝 Installation Log Example

```
=========================================
Microsoft 365 Applications Installer
SBS Federal
Version: 1.0.0
=========================================

[2025-12-17 10:00:00] ℹ️  Checking available disk space...
[2025-12-17 10:00:01] ✅ Sufficient disk space available: 50GB

===== Installing Microsoft Office =====
[2025-12-17 10:00:02] ℹ️  Downloading Microsoft Office...
[2025-12-17 10:05:15] ✅ Downloaded Microsoft Office
[2025-12-17 10:05:16] ℹ️  Installing Microsoft Office...
[2025-12-17 10:15:30] ✅ Microsoft Office installed successfully

===== Installing Microsoft Teams =====
[2025-12-17 10:15:31] ℹ️  Downloading Microsoft Teams...
[2025-12-17 10:18:22] ✅ Downloaded Microsoft Teams
[2025-12-17 10:18:23] ℹ️  Installing Microsoft Teams...
[2025-12-17 10:20:45] ✅ Microsoft Teams installed successfully

...

=========================================
INSTALLATION COMPLETE
=========================================

Total Applications: 8
✅ Successfully Installed: 8
⏭️  Already Installed/Skipped: 0
❌ Failed: 0

Log file: /Users/username/.m365-installer/installer.log
```

---

## 🔍 Troubleshooting

### Installation Fails

**Issue:** Download fails or times out

**Solution:**
```bash
# Check internet connection
ping microsoft.com

# Check disk space
df -h

# Re-run installer
m365-install

# Check logs
tail -100 ~/.m365-installer/installer.log
```

### App Won't Open After Install

**Issue:** Application crashes or won't launch

**Solution:**
```bash
# Reset quarantine attribute
sudo xattr -r -d com.apple.quarantine /Applications/Microsoft\ *.app

# Or for specific app
sudo xattr -r -d com.apple.quarantine /Applications/Microsoft\ Word.app

# Relaunch application
```

### Sign-In Issues

**Issue:** Cannot sign in to Microsoft 365

**Solution:**
```bash
# Clear cached credentials
rm -rf ~/Library/Group\ Containers/UBF8T346G9.Office/

# Remove saved passwords (Keychain Access)
1. Open Keychain Access
2. Search for "Microsoft"
3. Delete old credentials
4. Restart Office app and sign in again
```

### OneDrive Sync Problems

**Issue:** OneDrive not syncing files

**Solution:**
```bash
# Reset OneDrive
1. Quit OneDrive
2. Launch OneDrive
3. Sign out and sign in again
4. Reselect folders to sync

# Or reinstall OneDrive
# Run installer again - it will detect and reinstall
```

### Automatic Updates Not Working

**Issue:** Apps not updating automatically

**Solution:**
```bash
# Check Microsoft AutoUpdate
open "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"

# Manually trigger update
# Open any Office app → Help → Check for Updates

# Reset MAU preferences
defaults delete com.microsoft.autoupdate2
```

---

## 🎓 Best Practices

### For IT Administrators

1. **Deploy via Intune**
   - Assign to new hire groups
   - Set as required installation
   - Monitor installation success rate

2. **Pre-configure Settings**
   - Use Config Profiles for OneDrive sync
   - Deploy Teams policies
   - Configure Edge settings

3. **User Communication**
   - Send pre-installation email
   - Provide sign-in credentials
   - Share quick start guide

### For End Users

1. **Before Installation**
   - Ensure 10GB+ free space
   - Connect to reliable internet
   - Have SBS Federal credentials ready

2. **During Installation**
   - Don't close Terminal
   - Don't sleep the computer
   - Wait for completion message

3. **After Installation**
   - Sign in to all apps with same account
   - Configure OneDrive sync
   - Set up Teams notifications
   - Check for updates

---

## 📊 System Requirements

### Minimum Requirements
- **macOS:** 10.14 (Mojave) or later
- **Disk Space:** 10 GB available
- **RAM:** 4 GB (8 GB recommended)
- **Internet:** Broadband connection
- **Processor:** Intel or Apple Silicon

### Recommended
- **macOS:** 11.0 (Big Sur) or later
- **Disk Space:** 20 GB available
- **RAM:** 8 GB or more
- **Internet:** High-speed broadband
- **Processor:** Apple Silicon (M1/M2/M3)

---

## 🔐 Security & Privacy

### What the Installer Does

- ✅ Downloads from official Microsoft CDN only
- ✅ Verifies package signatures
- ✅ Logs all operations
- ✅ No credential storage
- ✅ Cleans up temporary files

### What the Installer Does NOT Do

- ❌ Store or transmit passwords
- ❌ Modify system security settings
- ❌ Access user data
- ❌ Install third-party software
- ❌ Send telemetry to external servers

### Data Collected

- Installation success/failure status
- Application versions installed
- macOS version and architecture
- Disk space and system info (for logs only)

**All data stays local - nothing sent externally**

---

## 📞 Support

### Internal Support
- **Email:** it@sbsfederal.com
- **Documentation:** This file
- **Logs:** `~/.m365-installer/installer.log`

### Microsoft Resources
- **Microsoft 365 Help:** https://support.microsoft.com/office
- **Teams Support:** https://support.microsoft.com/teams
- **OneDrive Help:** https://support.microsoft.com/onedrive
- **Edge Support:** https://support.microsoft.com/microsoft-edge

---

## 🎉 Quick Command Reference

```bash
# Run installer
m365-install

# View installation log
tail -100 ~/.m365-installer/installer.log

# Check installed Office version
defaults read /Applications/Microsoft\ Word.app/Contents/Info.plist CFBundleShortVersionString

# Open Microsoft AutoUpdate
open "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"

# Check OneDrive sync status
ps aux | grep OneDrive

# View all installed M365 apps
ls -la /Applications | grep Microsoft
```

---

**For deployment to Intune, see the intune/ directory**

**Last Updated:** 2025-12-17
**Version:** 1.0.0
**Company:** SBS Federal
