# Mac Dev Setup - Help Desk Deployment Checklist

## SBS Federal IT Help Desk Guide

**Version:** 2.1.0
**Estimated Time:** 45-60 minutes
**Contact:** it@sbsfederal.com

---

## Quick Reference

| Item | Value |
|------|-------|
| Package Name | SBS Federal Mac Dev Setup |
| Version | 2.1.0 |
| Build Command | `./build-package.sh` |
| Detection File | `/Library/Application Support/MacDevSetup/version.txt` |
| User Command | `mac-dev-setup` |
| Min OS | macOS 10.15 |
| Disk Space | 20 GB |

---

## Pre-Deployment Checklist

### 1. Gather Required Tools
- [ ] Mac with Xcode Command Line Tools
- [ ] IntuneAppUtil (from Microsoft GitHub)
- [ ] Intune admin access

### 2. Gather Required Files
- [ ] `mac-dev-setup.sh` (main script)
- [ ] `install.sh` (Intune wrapper)
- [ ] `uninstall.sh` (removal script)
- [ ] `detection.sh` (detection script)
- [ ] `preinstall.sh` (pre-checks)
- [ ] `postinstall.sh` (post-tasks)
- [ ] `build-package.sh` (build script)

### 3. Verify Environment
- [ ] Xcode CLT installed: `xcode-select --version`
- [ ] Navigate to: `packages/macos/mac-dev-setup/intune/`
- [ ] Scripts are executable: `chmod +x *.sh`

---

## Package Build Checklist

### 4. Build the PKG Package
```bash
cd packages/macos/mac-dev-setup/intune/
./build-package.sh
```
- [ ] Build completes without errors
- [ ] `MacDevSetup-2.1.0.pkg` created

### 5. Convert for Intune
```bash
./IntuneAppUtil -c MacDevSetup-2.1.0.pkg -o . -i com.sbsfederal.macdevsetup -n 2.1.0
```
- [ ] `MacDevSetup-2.1.0.intunemac` created

---

## Intune Upload Checklist

### 6. Access Intune
- [ ] Navigate to https://intune.microsoft.com
- [ ] Sign in with admin credentials
- [ ] Go to Apps > macOS

### 7. Add New App
- [ ] Click + Add
- [ ] Select "Line-of-business app"
- [ ] Click Select

### 8. App Information
- [ ] Name: `SBS Federal Mac Dev Setup`
- [ ] Description: `Automated dev environment setup. Run mac-dev-setup after install.`
- [ ] Publisher: `SBS Federal`
- [ ] Version: `2.1.0`
- [ ] Category: `Developer Tools`

### 9. Upload Package
- [ ] Click "Select app package file"
- [ ] Upload `MacDevSetup-2.1.0.intunemac`
- [ ] Wait for upload to complete

### 10. Detection Rules
- [ ] Select: Use custom detection script
- [ ] Upload: `detection.sh`
- [ ] Run as 32-bit: No
- [ ] Enforce signature check: No

### 11. Requirements
- [ ] Operating system: macOS 10.15 or later
- [ ] Architecture: x64, ARM64
- [ ] Disk space: 20480 MB
- [ ] Memory: 4096 MB

### 12. Review and Create
- [ ] Review all settings
- [ ] Click Create
- [ ] Wait for app to finish uploading

---

## Assignment Checklist

### 13. Pilot Deployment
- [ ] Add assignment: Available for enrolled devices
- [ ] Select: IT Test Devices group
- [ ] Save assignment

### 14. Verify Pilot Installation
- [ ] Wait for Intune sync (or force sync)
- [ ] Install from Company Portal on test Mac
- [ ] Verify version file exists:
  ```bash
  cat "/Library/Application Support/MacDevSetup/version.txt"
  ```
- [ ] Run `mac-dev-setup` as test user
- [ ] Verify applications installed:
  - [ ] Docker Desktop
  - [ ] Visual Studio Code
  - [ ] Cursor
  - [ ] iTerm2
  - [ ] IntelliJ IDEA CE
- [ ] Verify desktop shortcuts created
- [ ] Review logs for errors

### 15. Production Deployment
- [ ] Add assignment: Available for enrolled devices
- [ ] Select: All Developers or target group
- [ ] Save assignment
- [ ] Send user communication

---

## User Communication Template

**Subject:** New: Mac Dev Setup Available in Company Portal

**Body:**
```
Hi Team,

The Mac Dev Setup package is now available in Company Portal.

TO INSTALL:
1. Open Company Portal
2. Search for "Mac Dev Setup"
3. Click Install
4. After installation completes, open Terminal
5. Run: mac-dev-setup
6. Enter your password when prompted
7. Wait 45-90 minutes for all tools to install

WHAT GETS INSTALLED:
- Docker, Podman, VS Code, Cursor, IntelliJ
- Kubernetes tools (kubectl, helm, k9s)
- Cloud CLIs (AWS, Azure, GCP)
- Git, Terraform, Ansible, and more

Need help? Contact it@sbsfederal.com

IT Department
```

---

## Post-Deployment Verification

### 16. Monitor Deployment
- [ ] Check Apps > Monitor > App install status
- [ ] Review installation success rate
- [ ] Identify and resolve failures
- [ ] Target: >95% success rate

### 17. Verify on Sample Device
```bash
# Check Intune installation
ls -la "/Library/Application Support/MacDevSetup/"

# Check version
cat "/Library/Application Support/MacDevSetup/version.txt"

# Check detection
./detection.sh && echo "Detected" || echo "Not detected"

# Check user ran script
cat ~/.mac-dev-setup.log | tail -50

# Check installed apps
brew list --cask
```

---

## Troubleshooting Quick Reference

### Check Installation Logs
```bash
# Intune logs
cat /Library/Logs/MacDevSetup/intune-install.log

# Preinstall logs
cat /Library/Logs/MacDevSetup/preinstall.log

# User execution logs
cat ~/.mac-dev-setup.log

# Show errors only
grep -i "error\|fail\|❌" ~/.mac-dev-setup.log
```

### Force Reinstall
```bash
# Remove version file
sudo rm "/Library/Application Support/MacDevSetup/version.txt"

# Sync Intune (or wait for auto-sync)
# Intune will detect as not installed and reinstall
```

### Manual Installation Test
```bash
# Install PKG locally (for testing)
sudo installer -pkg MacDevSetup-2.1.0.pkg -target /

# Run script
mac-dev-setup
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Command not found" | Check `/usr/local/bin/mac-dev-setup` exists |
| Detection fails | Check version.txt, run `detection.sh` manually |
| Apps don't install | User must run `mac-dev-setup` after Intune install |
| Homebrew fails | Check network, run `brew doctor` |
| No disk space | Free up 20GB minimum |

---

## Sign-Off

**Deployed By:** _________________________ **Date:** _____________

**Pilot Verified By:** _________________________ **Date:** _____________

**Production Approved By:** _________________________ **Date:** _____________

**Notes:**
```




```

---

## Support Escalation

| Level | Contact | Response Time |
|-------|---------|---------------|
| Tier 1 | Help Desk | Same day |
| Tier 2 | IT Admin | 4 hours |
| Tier 3 | it@sbsfederal.com | 24 hours |

---

## Files Reference

### Package Location
```
packages/macos/mac-dev-setup/
├── scripts/
│   └── mac-dev-setup.sh         # Main script
├── intune/
│   ├── install.sh               # Intune wrapper
│   ├── uninstall.sh             # Uninstall script
│   ├── detection.sh             # Detection script
│   ├── preinstall.sh            # Pre-checks
│   ├── postinstall.sh           # Post-tasks
│   └── build-package.sh         # Build script
└── docs/
    ├── INTUNE-ADMIN-GUIDE.md    # Full admin guide
    └── HELPDESK-DEPLOYMENT-CHECKLIST.md  # This file
```

### On Target Mac
```
/Library/Application Support/MacDevSetup/
├── mac-dev-setup.sh             # Installed script
├── version.txt                  # Detection file
├── uninstall.sh                 # Uninstaller
└── *.md                         # Documentation

/Library/Logs/MacDevSetup/
├── intune-install.log
├── preinstall.log
└── postinstall.log

/usr/local/bin/
└── mac-dev-setup               # Command wrapper

~/.mac-dev-setup.log            # User execution log
```

---

*SBS Federal IT Department - Confidential*
