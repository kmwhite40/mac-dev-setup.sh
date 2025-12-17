# Quick Start Guide - Mac Dev Setup

This guide will get you up and running in 5 minutes.

## Installation (3 Steps)

### Step 1: Download

```bash
# Clone the repository
git clone <repository-url>
cd mac-dev-setup.sh

# OR download directly
curl -O https://your-repo-url/mac-dev-setup.sh
```

### Step 2: Make Executable

```bash
chmod +x mac-dev-setup.sh
```

### Step 3: Run

```bash
./mac-dev-setup.sh
```

**Note:** You'll be asked for your password for system updates.

## What Happens

1. ✅ Installs Homebrew (if needed)
2. ✅ Updates macOS system
3. ✅ Installs all applications (Docker, VS Code, Cursor, etc.)
4. ✅ Installs all CLI tools (git, kubectl, terraform, etc.)
5. ✅ Creates desktop shortcuts
6. ✅ Logs everything to `~/.mac-dev-setup.log`

## Estimated Time

- **First run:** 30-60 minutes (depends on internet speed)
- **Subsequent runs:** 5-15 minutes (only installs missing packages)

## After Installation

### 1. Authenticate with GitHub (2 minutes)

```bash
gh auth login
gh auth setup-git
```

### 2. Authenticate with GitLab (1 minute)

```bash
glab auth login
```

### 3. Configure Git (1 minute)

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 4. Start Docker (30 seconds)

- Open Docker from Desktop shortcut or Applications
- Wait for Docker to start

### 5. Done! 🎉

Check your Desktop for application shortcuts and start coding!

## Quick Commands

### View Installation Log
```bash
tail -f ~/.mac-dev-setup.log
```

### Check What's Installed
```bash
brew list --cask     # GUI apps
brew list --formula  # CLI tools
```

### Force Update Now
```bash
rm ~/.mac-dev-setup-last-update
./mac-dev-setup.sh
```

### Add More Apps
Edit the script and add:
```bash
install_cask "app-name"      # For GUI apps
install_formula "tool-name"  # For CLI tools
```

## Common Issues

### "Permission Denied"
```bash
chmod +x mac-dev-setup.sh
```

### "Command not found: brew"
The script will install Homebrew automatically. If it fails, install manually:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Desktop Shortcuts Missing
They're created in `~/Desktop/`. Check Finder → Desktop.

## Update Schedule

The script automatically updates your system:
- **Every 4 days:** Full macOS + Homebrew update
- **Between updates:** Only installs missing packages

To change this, edit `UPDATE_INTERVAL_DAYS=4` in the script.

## Need Help?

See [README.md](README.md) for detailed documentation and troubleshooting.

---

That's it! You're ready to go. Happy coding! 🚀
