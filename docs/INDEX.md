# Mac Development Environment Setup - Documentation Index

Complete documentation for the automated Mac development environment setup script.

## Quick Navigation

📋 **New User?** Start here: [QUICK_START.md](QUICK_START.md)
📖 **Full Documentation:** [README.md](README.md)
🔧 **Having Issues?** Check: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
📊 **How It Works:** [OPERATIONS.md](OPERATIONS.md)

---

## Document Overview

### [QUICK_START.md](QUICK_START.md) - 5 Minute Guide
**Read this first if you just want to get started quickly.**

- ✅ 3-step installation process
- ✅ What happens during setup
- ✅ Essential post-installation steps
- ✅ Most common commands
- ⏱️ **Reading time:** 5 minutes

**Perfect for:** First-time users, quick reference

---

### [README.md](README.md) - Complete Documentation
**Comprehensive guide covering everything.**

- 📦 Full list of what gets installed
- ⚙️ Configuration options
- 🔐 Security considerations
- 📝 Log file management
- 🎯 Advanced usage
- 🤖 Automation setup
- ❓ FAQ section
- ⏱️ **Reading time:** 20 minutes

**Perfect for:** Understanding all features, customization, automation

---

### [OPERATIONS.md](OPERATIONS.md) - Technical Deep Dive
**Detailed execution flow and operations.**

- 🔄 Complete execution flowchart
- 📊 Step-by-step process breakdown
- ⚡ Performance characteristics
- 🗂️ File system changes
- 📉 Exit codes and monitoring
- 🐛 Debug procedures
- ⏱️ **Reading time:** 15 minutes

**Perfect for:** Technical users, troubleshooting, system administrators

---

### [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem Solving
**Solutions for common issues.**

- 🚨 Installation problems
- 🔒 Permission issues
- 🍺 Homebrew troubleshooting
- 📦 Package failures
- 🌐 Network problems
- 💾 Performance issues
- 🔧 Recovery procedures
- ⏱️ **Reading time:** 30 minutes (reference as needed)

**Perfect for:** Solving specific issues, error recovery

---

## Quick Reference

### Installation (One-Time)

```bash
# Download, make executable, and run
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh
```

### Essential Commands

```bash
# View installation log
tail -f ~/.mac-dev-setup.log

# Force system update
rm ~/.mac-dev-setup-last-update && ./mac-dev-setup.sh

# Check what's installed
brew list --cask && brew list --formula

# Authenticate GitHub
gh auth login && gh auth setup-git

# Authenticate GitLab
glab auth login
```

### Key Files

| File | Purpose |
|------|---------|
| `mac-dev-setup.sh` | Main installation script |
| `~/.mac-dev-setup.log` | Installation log |
| `~/.mac-dev-setup-last-update` | Update timestamp tracker |
| `~/Desktop/*` | Application shortcuts |

---

## What This Script Does

### 🎯 Main Features

1. **Automated Installation**
   - Installs Homebrew automatically
   - Installs 14 GUI applications
   - Installs 21 CLI tools
   - Creates desktop shortcuts

2. **Forced Updates**
   - macOS system updates every 4 days
   - Homebrew package updates
   - Automatic tracking

3. **Smart Installation**
   - Checks for existing packages
   - Skips already installed items
   - Individual error handling

4. **Developer Tools**
   - GitHub & GitLab integration
   - Cursor AI editor
   - Docker, Kubernetes, cloud CLIs
   - Database management tools

### 📦 Full Installation List

**GUI Applications (14):**
Docker, Podman, iTerm2, VS Code, Cursor, IntelliJ IDEA CE, Obsidian, Postman, pgAdmin4, TablePlus, DBeaver, MongoDB Compass, GitHub Desktop, GitLab Desktop

**CLI Tools (21):**
git, gh, glab, maven, node, python, openjdk, go, dotnet, kubectl, helm, awscli, azure-cli, google-cloud-sdk, terraform, ansible, k9s, curl, httpie, k6, coder

---

## Typical Workflow

### First Time Setup

```
1. Read QUICK_START.md (5 min)
2. Run script (45-90 min)
3. Follow post-installation steps (10 min)
4. Start coding!
```

### Regular Usage

```
1. Run script weekly or monthly
2. Script checks if 4 days passed
3. Updates if needed
4. Installs any missing packages
5. Complete in 2-10 minutes
```

### When Problems Occur

```
1. Check log file for errors
2. Open TROUBLESHOOTING.md
3. Find your error in table of contents
4. Follow solution steps
5. Re-run script
```

---

## Configuration Guide

### Change Update Frequency

Edit [mac-dev-setup.sh](mac-dev-setup.sh) line 14:
```bash
UPDATE_INTERVAL_DAYS=4  # Change to desired days
```

### Add/Remove Applications

Edit [mac-dev-setup.sh](mac-dev-setup.sh) lines 172-185 (GUI apps) or 186-206 (CLI tools):
```bash
# Add new app
install_cask "new-app-name"

# Remove app (comment out with #)
# install_cask "unwanted-app"
```

### Customize Desktop Shortcuts

Edit [mac-dev-setup.sh](mac-dev-setup.sh) lines 152-161:
```bash
declare -A apps=(
    ["Your App"]="/Applications/Your App.app"
)
```

---

## Support Resources

### Documentation Files

- **Quick Start:** For immediate setup
- **README:** For complete information
- **Operations:** For technical details
- **Troubleshooting:** For problem solving

### External Resources

- **Homebrew:** https://docs.brew.sh/
- **GitHub CLI:** https://cli.github.com/manual/
- **GitLab CLI:** https://glab.readthedocs.io/
- **macOS Support:** https://support.apple.com/

### Log Files

```bash
# Main log
~/.mac-dev-setup.log

# Homebrew logs
~/Library/Logs/Homebrew/

# System logs
/var/log/install.log
```

---

## Version Information

| Component | Version |
|-----------|---------|
| Script | 2.0 |
| Documentation | 1.0 |
| Last Updated | 2025-12-17 |

---

## License & Credits

This script is provided as-is for personal and commercial use.

**Includes:**
- Automated Homebrew installation
- macOS system update integration
- Smart package management
- Desktop shortcut creation
- Comprehensive logging

---

## Next Steps

### If you're new:
1. Read [QUICK_START.md](QUICK_START.md)
2. Run the script
3. Follow post-installation steps

### If you want to customize:
1. Read [README.md](README.md) Configuration section
2. Edit [mac-dev-setup.sh](mac-dev-setup.sh)
3. Test your changes

### If you have issues:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review log file: `~/.mac-dev-setup.log`
3. Search for your specific error

### If you want to understand how it works:
1. Read [OPERATIONS.md](OPERATIONS.md)
2. Review the flowchart
3. Check the execution phases

---

## Quick Command Reference

```bash
# Installation
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh

# Maintenance
brew update && brew upgrade && brew cleanup

# Logs
tail -50 ~/.mac-dev-setup.log                    # Last 50 lines
grep "❌" ~/.mac-dev-setup.log                   # Show errors
grep "✅" ~/.mac-dev-setup.log | wc -l           # Count successes

# Authentication
gh auth login && gh auth setup-git               # GitHub
glab auth login                                  # GitLab

# Updates
rm ~/.mac-dev-setup-last-update                  # Force update
./mac-dev-setup.sh                               # Run script

# Verification
brew list --cask                                 # GUI apps
brew list --formula                              # CLI tools
brew doctor                                      # Health check
```

---

**🎉 You're all set! Choose your documentation path above and get started!**
