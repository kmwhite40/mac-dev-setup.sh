# Troubleshooting Guide

Common issues and solutions for the Mac Dev Setup script.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Permission Problems](#permission-problems)
3. [Homebrew Issues](#homebrew-issues)
4. [Package Installation Failures](#package-installation-failures)
5. [System Update Problems](#system-update-problems)
6. [Desktop Shortcuts Issues](#desktop-shortcuts-issues)
7. [Network Problems](#network-problems)
8. [Performance Issues](#performance-issues)
9. [Recovery Procedures](#recovery-procedures)

---

## Installation Issues

### Error: "Permission denied" when running script

**Symptom:**
```
bash: ./mac-dev-setup.sh: Permission denied
```

**Solution:**
```bash
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh
```

**Why:** The script file doesn't have execute permissions.

---

### Error: "Please do not run this script as root"

**Symptom:**
```
❌ Please do not run this script as root or with sudo
```

**Solution:**
```bash
# Don't do this:
sudo ./mac-dev-setup.sh

# Do this instead:
./mac-dev-setup.sh
```

**Why:** The script will request sudo when needed. Running the entire script as root can cause permission issues.

---

### Script exits immediately with "set -e"

**Symptom:** Script stops at first error without explanation.

**Solution:**
```bash
# Run without exit-on-error to see all errors
bash ./mac-dev-setup.sh
```

**Or temporarily disable:**
```bash
# Edit script, comment out line 3:
# set -e
```

**Why:** `set -e` causes the script to exit on any error. Disable temporarily to diagnose issues.

---

## Permission Problems

### Cannot write to log file

**Symptom:**
```
tee: /Users/yourname/.mac-dev-setup.log: Permission denied
```

**Solution:**
```bash
# Check file permissions
ls -l ~/.mac-dev-setup.log

# Fix permissions
chmod 644 ~/.mac-dev-setup.log

# Or delete and recreate
rm ~/.mac-dev-setup.log
./mac-dev-setup.sh
```

---

### "Operation not permitted" for system updates

**Symptom:**
```
softwareupdate: Operation not permitted
```

**Solution:**
```bash
# Grant Full Disk Access to Terminal:
1. System Preferences → Security & Privacy → Privacy
2. Select "Full Disk Access"
3. Click lock to make changes
4. Add Terminal/iTerm to the list
5. Restart Terminal
```

---

### Cannot create desktop shortcuts

**Symptom:**
```
ln: /Users/yourname/Desktop/Cursor: Permission denied
```

**Solution:**
```bash
# Check Desktop permissions
ls -ld ~/Desktop

# Fix permissions
chmod 755 ~/Desktop

# Grant Terminal access to Desktop
# System Preferences → Security & Privacy → Files and Folders
```

---

## Homebrew Issues

### Homebrew not found after installation

**Symptom:**
```
command not found: brew
```

**Solution (Intel Mac):**
```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

**Solution (Apple Silicon):**
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Then reload:**
```bash
source ~/.zprofile
```

---

### Homebrew installation fails

**Symptom:**
```
Failed to install Homebrew
```

**Solution:**
```bash
# Manual installation
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow on-screen instructions
# Then re-run the dev setup script
./mac-dev-setup.sh
```

---

### "brew: command not found" during script execution

**Symptom:** Script says Homebrew is installed but can't find it.

**Solution:**
```bash
# Find where Homebrew is installed
which brew

# If not found, check common locations
ls /opt/homebrew/bin/brew
ls /usr/local/bin/brew

# Add to PATH manually
export PATH="/opt/homebrew/bin:$PATH"  # Apple Silicon
# or
export PATH="/usr/local/bin:$PATH"     # Intel

# Re-run script
./mac-dev-setup.sh
```

---

### Homebrew doctor shows warnings

**Symptom:**
```
⚠️  Homebrew doctor found some issues (non-critical)
```

**Solution:**
```bash
# Run doctor directly
brew doctor

# Read warnings and fix as suggested
# Common fixes:

# Outdated Xcode Command Line Tools
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# Config issues
brew update-reset
brew update
```

---

## Package Installation Failures

### Specific cask fails to install

**Symptom:**
```
❌ Failed to install docker
```

**Solution:**
```bash
# Check error in log
grep "docker" ~/.mac-dev-setup.log

# Try manual installation
brew install --cask docker --verbose

# If it's a known issue, check Homebrew
brew info docker

# Alternative: Install from App Store or direct download
```

---

### Multiple packages fail with "checksum mismatch"

**Symptom:**
```
Error: SHA256 mismatch
```

**Solution:**
```bash
# Clear Homebrew cache
rm -rf ~/Library/Caches/Homebrew/*

# Update Homebrew
brew update

# Re-run installation
./mac-dev-setup.sh
```

---

### Formula not found

**Symptom:**
```
Error: No available formula with the name "package-name"
```

**Solution:**
```bash
# Update Homebrew
brew update

# Search for correct name
brew search package-name

# If package doesn't exist anymore, edit script to remove it
# Or replace with alternative
```

---

### Cask already installed but script tries to reinstall

**Symptom:** Reinstallation errors for existing apps.

**Solution:**
```bash
# Check what's installed
brew list --cask | grep app-name

# If truly installed, the script should skip it
# If there's a name mismatch, check:
brew info app-name

# Update script with correct cask name
```

---

## System Update Problems

### System update hangs or takes too long

**Symptom:** `softwareupdate` appears stuck.

**Solution:**
```bash
# Check if it's actually running (in another terminal)
ps aux | grep softwareupdate

# Check network activity
nettop -P -J bytes_in,bytes_out

# If truly stuck (> 1 hour with no activity)
# Cancel with Ctrl+C
# Then run manually:
sudo softwareupdate -l
sudo softwareupdate -ia
```

---

### "Authentication required" repeated prompts

**Symptom:** Constantly asked for password.

**Solution:**
```bash
# This is normal for system updates
# Each update component may require authentication
# Enter password when prompted

# To avoid in future, you can comment out system updates:
# Edit script lines 210-216
```

---

### System update fails with "Not enough disk space"

**Symptom:**
```
Error: You need at least X GB of free space
```

**Solution:**
```bash
# Check available space
df -h

# Free up space:
# 1. Empty Trash
# 2. Remove large files
# 3. Clean Homebrew cache
brew cleanup -s
rm -rf ~/Library/Caches/Homebrew/*

# 4. Remove old iOS backups
# 5. Use Disk Utility → Manage to find large files

# Once space is freed, re-run script
./mac-dev-setup.sh
```

---

### Update timestamp file corrupted

**Symptom:** Script always thinks it's time to update or never updates.

**Solution:**
```bash
# Remove timestamp file
rm ~/.mac-dev-setup-last-update

# Re-run script (will do full update)
./mac-dev-setup.sh

# Or set specific timestamp (advanced)
date +%s > ~/.mac-dev-setup-last-update
```

---

## Desktop Shortcuts Issues

### No shortcuts appear on Desktop

**Symptom:** Script completes but Desktop is empty.

**Solution:**
```bash
# Check if shortcuts were created
ls -la ~/Desktop/

# If they exist but don't show:
# 1. Check Finder preferences
# Finder → Preferences → General → Show these items on desktop

# 2. Restart Finder
killall Finder

# 3. Check if apps are actually installed
ls /Applications/ | grep -i cursor
```

---

### Shortcut points to wrong location

**Symptom:** Clicking shortcut shows "Application not found".

**Solution:**
```bash
# Check where symlink points
ls -l ~/Desktop/AppName

# Remove broken symlink
rm ~/Desktop/AppName

# Find correct application location
mdfind -name "AppName.app"

# Recreate manually
ln -s "/correct/path/to/App.app" ~/Desktop/AppName
```

---

### Shortcuts created but apps won't open

**Symptom:** Double-clicking does nothing or shows error.

**Solution:**
```bash
# Open app directly first time (bypass Gatekeeper)
open /Applications/AppName.app

# Click "Open" in the security dialog

# Then Desktop shortcut should work
```

---

## Network Problems

### Downloads fail or timeout

**Symptom:**
```
curl: (28) Operation timed out
```

**Solution:**
```bash
# Check internet connection
ping -c 3 google.com

# Check DNS
nslookup github.com

# Try different network
# - Switch from WiFi to Ethernet
# - Try different WiFi network
# - Disable VPN temporarily

# Increase Homebrew timeout (edit script or run manually)
export HOMEBREW_CURL_RETRIES=10
./mac-dev-setup.sh
```

---

### SSL/TLS certificate errors

**Symptom:**
```
SSL certificate problem: unable to get local issuer certificate
```

**Solution:**
```bash
# Update system certificates
sudo security update-ca-trust

# Or temporarily bypass (not recommended for production)
export HOMEBREW_CURL_UNSAFE=1
./mac-dev-setup.sh
```

---

### Slow download speeds

**Symptom:** Installation taking hours.

**Solution:**
```bash
# Use fastest Homebrew mirror
export HOMEBREW_BOTTLE_DOMAIN=https://homebrew.bintray.com

# Or check network speed
speedtest-cli  # Install first: brew install speedtest-cli

# Consider running overnight or during off-peak hours
```

---

## Performance Issues

### Script is very slow

**Symptom:** Taking much longer than expected.

**Solution:**
```bash
# Normal times:
# First run: 45-90 minutes
# Update run: 15-45 minutes
# Subsequent: 2-10 minutes

# If much slower:
# 1. Check system resources
top

# 2. Check network speed (see above)

# 3. Run during off-peak hours

# 4. Close other applications

# 5. Check if disk is nearly full
df -h
```

---

### High CPU usage

**Symptom:** System becomes very slow during installation.

**Solution:**
```bash
# This is normal during:
# - Package compilation
# - System updates
# - Large downloads

# To reduce impact:
# - Close other applications
# - Don't use during active work
# - Run overnight

# Check what's using CPU
top -o cpu
```

---

### Disk space filling up rapidly

**Symptom:** Disk space disappearing during installation.

**Solution:**
```bash
# Check space usage
du -sh ~/Library/Caches/Homebrew
du -sh /Applications

# Clean up during installation
brew cleanup

# Remove downloads after installation
rm -rf ~/Library/Caches/Homebrew/downloads/*

# Monitor space
watch -n 5 df -h
```

---

## Recovery Procedures

### Complete Reset - Start Fresh

```bash
# 1. Remove all installed packages (CAREFUL!)
brew list --cask | xargs brew uninstall --cask
brew list --formula | xargs brew uninstall

# 2. Uninstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# 3. Remove script files
rm ~/.mac-dev-setup.log
rm ~/.mac-dev-setup-last-update
rm ~/Desktop/Cursor  # and other shortcuts

# 4. Re-run setup
./mac-dev-setup.sh
```

---

### Partial Reset - Keep Homebrew

```bash
# 1. Remove timestamp (force update)
rm ~/.mac-dev-setup-last-update

# 2. Clear log
rm ~/.mac-dev-setup.log

# 3. Update Homebrew
brew update
brew upgrade
brew cleanup

# 4. Re-run setup
./mac-dev-setup.sh
```

---

### Emergency Stop Recovery

If you stopped the script mid-execution (Ctrl+C):

```bash
# 1. Check what was being installed
tail -20 ~/.mac-dev-setup.log

# 2. Check for hung processes
ps aux | grep brew

# 3. Kill if necessary
killall brew

# 4. Clean up incomplete installations
brew cleanup

# 5. Re-run (script will skip completed items)
./mac-dev-setup.sh
```

---

### Log Analysis

```bash
# Find all errors
grep "❌" ~/.mac-dev-setup.log

# Find all warnings
grep "⚠️" ~/.mac-dev-setup.log

# Show last 50 lines
tail -50 ~/.mac-dev-setup.log

# Search for specific app
grep -i "docker" ~/.mac-dev-setup.log

# Show only timestamps and errors
grep "❌" ~/.mac-dev-setup.log | awk '{print $1, $2}'

# Count successful installations
grep "✅.*installed" ~/.mac-dev-setup.log | wc -l
```

---

## Getting Additional Help

### Collect Diagnostic Information

```bash
# System info
sw_vers
uname -m

# Homebrew info
brew --version
brew config

# Disk space
df -h

# Recent errors
tail -100 ~/.mac-dev-setup.log | grep "❌"

# Installed packages
brew list --versions > ~/installed-packages.txt
```

### Report Issues

When reporting issues, include:

1. macOS version: `sw_vers`
2. Chip type: `uname -m`
3. Error messages from log
4. Steps to reproduce
5. What you expected vs. what happened

### Useful Resources

- Homebrew docs: https://docs.brew.sh/
- macOS support: https://support.apple.com/
- Script log: `~/.mac-dev-setup.log`

---

## Preventive Measures

### Before Running Script

```bash
# 1. Backup important data
# 2. Ensure 30+ GB free space
df -h

# 3. Connect to reliable network
# 4. Close unnecessary applications
# 5. Disable sleep mode temporarily
caffeinate -s &
```

### Regular Maintenance

```bash
# Weekly
brew update
brew upgrade
brew cleanup

# Monthly
brew doctor
brew autoremove

# Check disk space
df -h

# Review log for recurring errors
grep "❌" ~/.mac-dev-setup.log | sort | uniq -c
```

---

**Last Updated:** 2025-12-17
