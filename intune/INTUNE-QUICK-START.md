# Intune Deployment - Quick Start Guide

Get your Mac Dev Setup package deployed to Intune in 60 minutes or less.

## Overview

This package transforms the Mac Dev Setup script into an Intune-deployable application that can be distributed through Company Portal.

## What You Get

### For IT Admins
- ✅ Automated Intune installation scripts
- ✅ Detection logic for compliance
- ✅ Pre/post-install hooks
- ✅ Comprehensive logging
- ✅ Uninstall capability
- ✅ LaunchAgent for auto-updates (optional)

### For End Users
- ✅ One-click install from Company Portal
- ✅ Desktop notifications
- ✅ Simple command: `mac-dev-setup`
- ✅ Desktop shortcuts to apps
- ✅ Full documentation included

## 5-Step Quick Deployment

### Step 1: Customize (10 minutes)

```bash
cd intune/

# Edit company settings
vim install.sh
# Update:
# - COMPANY_NAME="Your Company"
# - IT_SUPPORT_EMAIL="support@company.com"
# - UPDATE_INTERVAL_DAYS=4
```

### Step 2: Build Package (5 minutes)

```bash
# Build the .pkg
./build-package.sh

# Output: MacDevSetup-2.0.0.pkg
```

### Step 3: Convert for Intune (5 minutes)

```bash
# Download IntuneAppUtil if needed
# https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac

# Convert package
./IntuneAppUtil \
  -c MacDevSetup-2.0.0.pkg \
  -o . \
  -i com.company.macdevsetup \
  -n 2.0.0

# Output: MacDevSetup-2.0.0.intunemac
```

### Step 4: Upload to Intune (20 minutes)

1. **Sign in:** https://intune.microsoft.com
2. **Navigate:** Apps → macOS → Add
3. **Select:** Line-of-business app
4. **Upload:** MacDevSetup-2.0.0.intunemac
5. **Configure:**
   - Name: Mac Dev Setup
   - Publisher: Your Company IT
   - Category: Productivity
6. **Detection:** Upload `detection.sh`
7. **Requirements:** macOS 10.15+, 30GB disk
8. **Installation:**
   - Install command: `/bin/bash /tmp/macdevsetup/install.sh`
   - Uninstall command: `/bin/bash /Library/Application\ Support/MacDevSetup/uninstall.sh`
9. **Save**

### Step 5: Assign & Deploy (20 minutes)

1. **Create pilot group** in Azure AD
2. **Assign to pilot:** Available for enrolled devices
3. **Monitor installation** in Intune console
4. **Test on pilot devices**
5. **Roll out to production** after validation

## What Gets Installed

### System Files
```
/Library/Application Support/MacDevSetup/
├── mac-dev-setup.sh          (main script)
├── README.md                 (documentation)
├── QUICK_START.md
├── TROUBLESHOOTING.md
├── company-config.sh         (company settings)
├── uninstall.sh
└── version.txt               (for detection)

/Library/Logs/MacDevSetup/
├── intune-install.log
├── preinstall.log
└── postinstall.log

/Library/LaunchAgents/
└── com.company.macdevsetup.plist (optional auto-update)

/usr/local/bin/
└── mac-dev-setup             (command wrapper)
```

### User Files (Created on First Run)
```
~/Desktop/
├── Cursor                    (shortcut)
├── Visual Studio Code        (shortcut)
├── Docker                    (shortcut)
└── [other app shortcuts]

~/.mac-dev-setup.log          (user execution log)
~/.mac-dev-setup-last-update  (update tracker)
```

## User Experience

### Installation Flow

1. **User opens Company Portal**
   - Searches for "Mac Dev Setup"
   - Clicks "Install"

2. **Intune installs package**
   - Runs preinstall checks
   - Copies files to system
   - Runs postinstall configuration
   - Shows notification

3. **User opens Terminal**
   - Runs: `mac-dev-setup`
   - Script installs Homebrew
   - Updates macOS (if 4+ days)
   - Installs all applications
   - Creates desktop shortcuts

4. **Complete!**
   - User has full dev environment
   - Desktop shortcuts available
   - Auto-updates every 4 days

### Time Estimates

| Phase | Duration |
|-------|----------|
| Company Portal install | 1-2 min |
| User runs mac-dev-setup | 45-90 min (first time) |
| Subsequent runs | 5-15 min |

## Monitoring & Support

### Check Installation Status

**In Intune Console:**
```
Apps → Mac Dev Setup → Device install status
- View success/failed/in-progress
- Check error messages
- Export reports
```

**On Device:**
```bash
# Check if installed
ls -la "/Library/Application Support/MacDevSetup/"

# Run detection
/Library/Application\ Support/MacDevSetup/../detection.sh
echo $?  # Should return 0

# View installation logs
tail -100 /Library/Logs/MacDevSetup/intune-install.log

# View user execution logs
tail -100 ~/.mac-dev-setup.log
```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Installation fails | Check `/Library/Logs/MacDevSetup/preinstall.log` |
| Detection fails | Run `detection.sh` manually, check version.txt |
| Command not found | Check PATH, verify `/usr/local/bin/mac-dev-setup` exists |
| Apps don't install | User must run `mac-dev-setup` after Intune install |
| No desktop shortcuts | Desktop shortcuts created after user runs script |

## Configuration Options

### Disable macOS System Updates

For environments with separate patch management:

```bash
# Edit install.sh, in company-config.sh section:
SKIP_MACOS_UPDATES=true

# Then modify mac-dev-setup.sh to check this flag
# (requires custom modification)
```

### Change Update Frequency

```bash
# Edit install.sh:
UPDATE_INTERVAL_DAYS=7  # Weekly instead of every 4 days
```

### Customize Application List

```bash
# Edit mac-dev-setup.sh:

# Add apps (lines 224-237):
install_cask "your-new-app"

# Remove apps (comment out):
# install_cask "unwanted-app"
```

### Enable Auto-Updates

```bash
# Edit postinstall.sh, uncomment this line:
launchctl load /Library/LaunchAgents/com.company.macdevsetup.plist

# This runs script every Monday at 9 AM
# Modify schedule in install.sh if needed
```

## Testing Checklist

Before production deployment:

- [ ] Build package successfully
- [ ] Install on test Mac
- [ ] Verify detection works
- [ ] User can run `mac-dev-setup`
- [ ] Applications install correctly
- [ ] Desktop shortcuts created
- [ ] Logs are written
- [ ] Uninstall works
- [ ] Company settings are correct

## Production Rollout Strategy

### Phase 1: Pilot (1 week)
- Deploy to 5-10 users
- Collect feedback
- Fix any issues
- Verify success rate > 90%

### Phase 2: Early Adopters (2 weeks)
- Deploy to 50-100 users
- Monitor support tickets
- Refine documentation
- Train help desk

### Phase 3: General Deployment (4 weeks)
- Deploy to all users (optional) or make available
- Continuous monitoring
- Regular reporting

## Support Resources

### Documentation Files

All documentation is installed at:
```
/Library/Application Support/MacDevSetup/
```

Users can access:
- **README.md** - Complete documentation
- **QUICK_START.md** - 5-minute user guide
- **TROUBLESHOOTING.md** - Problem solving
- **OPERATIONS.md** - How it works

### Help Desk Scripts

**Check if installed:**
```bash
ls -la "/Library/Application Support/MacDevSetup/version.txt"
cat "/Library/Application Support/MacDevSetup/version.txt"
```

**View recent activity:**
```bash
tail -50 ~/.mac-dev-setup.log
grep "❌" ~/.mac-dev-setup.log  # Show errors
```

**Force reinstall:**
```bash
sudo rm "/Library/Application Support/MacDevSetup/version.txt"
# Intune will detect as not installed and reinstall
```

**Manual uninstall:**
```bash
sudo /Library/Application\ Support/MacDevSetup/uninstall.sh
```

## Security Notes

### What Requires Admin/Sudo
- Intune installation (automatic)
- macOS system updates
- Homebrew installation (first time)

### What Runs as User
- Application installation via Homebrew
- Desktop shortcut creation
- User preference configuration

### Network Requirements
- Access to Homebrew repositories
- Access to Apple Software Update servers
- Access to GitHub/GitLab for CLIs

### Data Privacy
- Logs contain: timestamps, package names, success/failure
- Logs do NOT contain: credentials, personal data, keystrokes
- No data sent to external servers (except package downloads)

## Next Steps

1. **Read full guide:** [README-INTUNE.md](README-INTUNE.md)
2. **Review checklist:** [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)
3. **Build package:** Run `./build-package.sh`
4. **Test locally:** Install on test Mac
5. **Deploy to Intune:** Upload and assign

## Quick Commands Reference

```bash
# Build package
./build-package.sh

# Test installation
sudo installer -pkg MacDevSetup-2.0.0.pkg -target /

# Check detection
./detection.sh && echo "Installed" || echo "Not installed"

# View logs
tail -f /Library/Logs/MacDevSetup/intune-install.log

# User command
mac-dev-setup

# Uninstall
sudo /Library/Application\ Support/MacDevSetup/uninstall.sh
```

## Success Metrics

Track these KPIs:

- **Installation success rate:** Target > 95%
- **Time to install:** Average < 60 minutes
- **Support tickets:** < 5% of deployments
- **User satisfaction:** > 4/5 rating
- **Adoption rate:** Track Company Portal installs

---

**Ready to deploy?** Follow the 5 steps above or see [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) for the complete process.

**Need help?** See [README-INTUNE.md](README-INTUNE.md) for detailed instructions and troubleshooting.

**Last Updated:** 2025-12-17
