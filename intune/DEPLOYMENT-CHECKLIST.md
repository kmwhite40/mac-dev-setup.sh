# Intune Deployment Checklist

Use this checklist to ensure successful deployment of Mac Dev Setup to your Intune environment.

## Pre-Deployment (30 minutes)

### ☐ 1. Customize Company Settings

- [ ] Edit `install.sh` - Update company name
- [ ] Edit `install.sh` - Update IT support email
- [ ] Edit `install.sh` - Set update interval (default: 4 days)
- [ ] Review applications list in `mac-dev-setup.sh`
- [ ] Remove unwanted applications
- [ ] Add additional applications if needed

**Files to edit:**
```bash
# Company configuration
vim install.sh
# Find and update:
COMPANY_NAME="Your Company"
IT_SUPPORT_EMAIL="itsupport@company.com"
UPDATE_INTERVAL_DAYS=4

# Application list
vim ../mac-dev-setup.sh
# Lines 224-237 (GUI apps)
# Lines 241-261 (CLI tools)
```

### ☐ 2. Test Scripts Locally

- [ ] Run preinstall checks: `sudo ./preinstall.sh`
- [ ] Test installation: `sudo ./install.sh`
- [ ] Verify detection: `./detection.sh`
- [ ] Test command: `mac-dev-setup`
- [ ] Review logs: `cat /Library/Logs/MacDevSetup/*.log`
- [ ] Test uninstall: `sudo ./uninstall.sh`

**Test commands:**
```bash
cd intune/

# Make executable
chmod +x *.sh

# Test pre-install
sudo ./preinstall.sh

# Test installation
sudo ./install.sh

# Test detection
./detection.sh
echo $?  # Should be 0

# Test the installed command
mac-dev-setup --help || mac-dev-setup

# Check logs
tail -50 /Library/Logs/MacDevSetup/intune-install.log

# Test uninstall
sudo ./uninstall.sh
```

### ☐ 3. Review Documentation

- [ ] Read `README-INTUNE.md` completely
- [ ] Understand package structure
- [ ] Review user experience flow
- [ ] Prepare support documentation for help desk

## Package Building (15 minutes)

### ☐ 4. Build the Package

- [ ] Navigate to intune directory: `cd intune/`
- [ ] Run build script: `./build-package.sh`
- [ ] Verify package created: `MacDevSetup-2.0.0.pkg`
- [ ] Check package size (should be ~60KB)
- [ ] Test package install: `sudo installer -pkg MacDevSetup-2.0.0.pkg -target /`

**Build commands:**
```bash
cd /path/to/mac-dev-setup.sh/intune

# Build package
./build-package.sh

# Verify
ls -lh MacDevSetup-2.0.0.pkg

# Test install
sudo installer -pkg MacDevSetup-2.0.0.pkg -target /

# Verify installation
ls -la "/Library/Application Support/MacDevSetup/"
```

### ☐ 5. Code Sign Package (Recommended)

- [ ] Obtain Developer ID Installer certificate
- [ ] Sign package: `productsign --sign "Developer ID Installer: YourCompany" ...`
- [ ] Verify signature: `pkgutil --check-signature MacDevSetup-2.0.0-signed.pkg`
- [ ] Optionally notarize with Apple

**Signing commands:**
```bash
# List available signing identities
security find-identity -v -p codesigning

# Sign the package
productsign \
  --sign "Developer ID Installer: Your Company" \
  MacDevSetup-2.0.0.pkg \
  MacDevSetup-2.0.0-signed.pkg

# Verify signature
pkgutil --check-signature MacDevSetup-2.0.0-signed.pkg
spctl -a -v --type install MacDevSetup-2.0.0-signed.pkg
```

### ☐ 6. Convert to .intunemac Format

- [ ] Download Intune App Wrapping Tool for macOS
- [ ] Run IntuneAppUtil on the package
- [ ] Verify .intunemac file created

**Conversion commands:**
```bash
# Download IntuneAppUtil if not already available
# https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac

# Convert package
./IntuneAppUtil \
  -c MacDevSetup-2.0.0.pkg \
  -o . \
  -i com.company.macdevsetup \
  -n 2.0.0

# Verify
ls -lh MacDevSetup-2.0.0.intunemac
```

## Intune Configuration (30 minutes)

### ☐ 7. Upload to Intune

- [ ] Sign in to https://intune.microsoft.com
- [ ] Navigate to Apps → macOS → Add
- [ ] Select "Line-of-business app"
- [ ] Upload .intunemac file
- [ ] Wait for upload to complete

### ☐ 8. Configure App Information

- [ ] **Name:** Mac Dev Setup
- [ ] **Description:** Automated development environment setup with Docker, VS Code, Cursor, IntelliJ, and cloud tools. Updates macOS and packages automatically every 4 days.
- [ ] **Publisher:** Your Company IT
- [ ] **Category:** Productivity
- [ ] **Information URL:** (your internal docs URL)
- [ ] **Privacy URL:** (your privacy policy URL)
- [ ] **Developer:** Your Company
- [ ] **Owner:** IT Department
- [ ] **Notes:** Requires ~30GB disk space and internet connection
- [ ] Upload app icon (512x512 PNG) - optional

### ☐ 9. Configure Detection Rules

Choose one method:

**Option A: Custom Script (Recommended)**
- [ ] Select "Use custom detection script"
- [ ] Upload `detection.sh`
- [ ] Set output type: "String"
- [ ] Detection string: Leave empty (script uses exit codes)

**Option B: File-based Detection**
- [ ] Detection rule type: "File"
- [ ] Path: `/Library/Application Support/MacDevSetup`
- [ ] File: `version.txt`
- [ ] Detection method: "File or folder exists"

### ☐ 10. Configure Requirements

- [ ] **Operating system:** macOS 10.15 or later
- [ ] **Architecture:** x64, ARM64 (both)
- [ ] **Disk space:** 30 GB
- [ ] **Physical memory:** 4 GB (recommended)
- [ ] **Processor:** 2 cores (recommended)

### ☐ 11. Configure Installation Settings

- [ ] **Install command:** `/bin/bash /tmp/macdevsetup/install.sh`
- [ ] **Uninstall command:** `/bin/bash /Library/Application\ Support/MacDevSetup/uninstall.sh`
- [ ] **Install behavior:** System
- [ ] **Device restart:** App install may force device restart
- [ ] **Return codes:**
  - Success: 0
  - Hard reboot: (leave empty)
  - Soft reboot: (leave empty)
  - Retry: (leave empty)
  - Failed: 1

## Pilot Deployment (1-2 days)

### ☐ 12. Create Pilot Group

- [ ] Create Azure AD group: "Mac Dev Setup - Pilot"
- [ ] Add 5-10 test users/devices
- [ ] Verify group membership

### ☐ 13. Assign to Pilot Group

- [ ] In app settings, go to Assignments
- [ ] Under "Available for enrolled devices", add pilot group
- [ ] Set notification: "Show notification"
- [ ] Save assignment

### ☐ 14. Monitor Pilot Installation

- [ ] Check "Device install status" in Intune
- [ ] Verify successful installations
- [ ] Review any failures
- [ ] Collect feedback from pilot users

**Monitoring locations:**
```
Intune Console:
- Apps → macOS → Mac Dev Setup → Device install status
- Devices → macOS → Select device → Installed apps

On Device:
- /Library/Logs/MacDevSetup/intune-install.log
- /Library/Logs/MacDevSetup/preinstall.log
- /Library/Logs/MacDevSetup/postinstall.log
- ~/.mac-dev-setup.log (after user runs it)
```

### ☐ 15. Test User Experience

For each pilot user, verify:
- [ ] App appears in Company Portal
- [ ] Installation completes successfully
- [ ] Notification appears after install
- [ ] User can run `mac-dev-setup` command
- [ ] Applications install correctly
- [ ] Desktop shortcuts created
- [ ] Logs are being written
- [ ] Documentation is accessible

### ☐ 16. Troubleshoot Issues

Common pilot issues:
- [ ] Installation fails → Check preinstall.log
- [ ] Detection fails → Run detection.sh manually
- [ ] Apps don't install → Check internet/Homebrew
- [ ] No desktop shortcuts → Check permissions
- [ ] Command not found → Check PATH configuration

## Production Deployment (1 week)

### ☐ 17. Review Pilot Results

- [ ] Success rate > 90%?
- [ ] All critical issues resolved?
- [ ] User feedback positive?
- [ ] Documentation complete?
- [ ] Support team trained?

### ☐ 18. Create Production Groups

- [ ] Create group: "Mac Dev Setup - Required" (mandatory install)
- [ ] Create group: "Mac Dev Setup - Available" (optional install)
- [ ] Add appropriate users/devices to each group

### ☐ 19. Assign to Production

**For Optional Installation (Available):**
- [ ] Add "Mac Dev Setup - Available" group
- [ ] Assignment type: "Available for enrolled devices"
- [ ] End user notification: "Show notification"

**For Mandatory Installation (Required):**
- [ ] Add "Mac Dev Setup - Required" group
- [ ] Assignment type: "Required"
- [ ] Set installation deadline (optional)
- [ ] End user notification: "Show notification"

### ☐ 20. Configure Auto-Update (Optional)

To enable automatic weekly runs:
- [ ] Edit postinstall.sh
- [ ] Uncomment LaunchAgent load line
- [ ] Rebuild package
- [ ] Upload new version

```bash
# In postinstall.sh, uncomment:
launchctl load /Library/LaunchAgents/com.company.macdevsetup.plist
```

## Post-Deployment (Ongoing)

### ☐ 21. Monitor Deployment

Weekly checks:
- [ ] Review installation success rate
- [ ] Check for failed installations
- [ ] Review error logs from devices
- [ ] Monitor help desk tickets
- [ ] Track user satisfaction

**Monitoring queries:**
```
Intune Console → Reports → Device compliance
Filter: Mac Dev Setup
Metrics: Installation status, Success rate, Failure reasons
```

### ☐ 22. Support Documentation

- [ ] Create internal knowledge base article
- [ ] Document common issues and solutions
- [ ] Create user guide for Company Portal installation
- [ ] Train help desk team on troubleshooting
- [ ] Set up ticketing system integration

### ☐ 23. Maintenance Plan

Monthly tasks:
- [ ] Review application list for updates
- [ ] Check for deprecated packages
- [ ] Update documentation
- [ ] Review user feedback
- [ ] Plan version updates

### ☐ 24. Version Updates

When releasing updates:
- [ ] Update version in package-info.json
- [ ] Update MIN_VERSION in detection.sh
- [ ] Update CHANGELOG
- [ ] Test thoroughly
- [ ] Deploy to pilot first
- [ ] Monitor before production rollout

## Success Criteria

### Installation Metrics
- [ ] ✓ Installation success rate > 95%
- [ ] ✓ Average installation time < 60 minutes
- [ ] ✓ Detection accuracy 100%
- [ ] ✓ User satisfaction score > 4/5

### User Experience
- [ ] ✓ Users can find app in Company Portal
- [ ] ✓ Installation process is clear
- [ ] ✓ Post-install instructions are followed
- [ ] ✓ Users successfully run mac-dev-setup
- [ ] ✓ Applications work as expected

### Support
- [ ] ✓ Help desk tickets < 5% of deployments
- [ ] ✓ All issues have documented solutions
- [ ] ✓ Average resolution time < 1 hour
- [ ] ✓ No critical unresolved issues

## Quick Reference Commands

### For IT Admins

```bash
# Build package
cd intune && ./build-package.sh

# Test installation
sudo installer -pkg MacDevSetup-2.0.0.pkg -target /

# Check detection
./detection.sh

# View logs
tail -f /Library/Logs/MacDevSetup/intune-install.log

# Force reinstall (remove detection marker)
sudo rm "/Library/Application Support/MacDevSetup/version.txt"

# Uninstall
sudo /Library/Application\ Support/MacDevSetup/uninstall.sh
```

### For End Users

```bash
# Run setup
mac-dev-setup

# View logs
tail -f ~/.mac-dev-setup.log

# View documentation
open "/Library/Application Support/MacDevSetup/README.md"

# Check installed apps
brew list --cask
```

## Rollback Plan

If critical issues occur:

1. **Immediate Actions:**
   - [ ] Remove from Required assignments
   - [ ] Set as "Uninstall" for affected groups
   - [ ] Communicate issue to users
   - [ ] Document the issue

2. **Investigation:**
   - [ ] Collect logs from affected devices
   - [ ] Identify root cause
   - [ ] Test fix in isolated environment

3. **Resolution:**
   - [ ] Fix issue in package
   - [ ] Test thoroughly
   - [ ] Deploy fix to pilot
   - [ ] Gradually re-enable production

## Contacts and Resources

### Internal Contacts
- **Intune Admin:** _______________
- **Package Developer:** _______________
- **Help Desk Lead:** _______________
- **Security Team:** _______________

### External Resources
- **Microsoft Intune Docs:** https://docs.microsoft.com/intune
- **Homebrew Docs:** https://docs.brew.sh
- **IntuneAppUtil:** https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac

### Project Documentation
- **Main README:** ../README.md
- **Intune Guide:** README-INTUNE.md
- **Troubleshooting:** ../TROUBLESHOOTING.md
- **Package Info:** package-info.json

---

## Sign-Off

### Pre-Deployment Approval
- [ ] IT Manager: _______________ Date: _______________
- [ ] Security Review: _______________ Date: _______________
- [ ] Change Control: _______________ Date: _______________

### Post-Pilot Approval
- [ ] Pilot Success Confirmed: _______________ Date: _______________
- [ ] Production Deployment Approved: _______________ Date: _______________

### Post-Deployment Review
- [ ] 30-Day Review Complete: _______________ Date: _______________
- [ ] Deployment Successful: YES / NO

---

**Last Updated:** 2025-12-17
**Checklist Version:** 1.0
