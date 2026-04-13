# COSMOS Deployment — Mac User Guide

## SBS Federal Developer Setup

**Version:** 1.0.0
**Last Updated:** 2026-04-13
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Overview](#overview)
2. [What Gets Installed](#what-gets-installed)
3. [Before You Begin](#before-you-begin)
4. [Step-by-Step Installation](#step-by-step-installation)
5. [After Installation](#after-installation)
6. [Weekly Auto-Updates](#weekly-auto-updates)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## Overview

The **COSMOS Deployment** script automatically installs and configures the full COSMOS development environment on your Mac. It handles everything — from Homebrew and Xcode CLI tools to browsers, editors, cloud CLIs, and Kubernetes tooling — in a single run.

Once installed, a weekly auto-update keeps all your software current without any manual effort.

---

## What Gets Installed

### Core Apps

| Application | Type | Description |
|-------------|------|-------------|
| Homebrew | Package manager | Required — installs everything else |
| Xcode Command Line Tools | System | Compiler, git, and build essentials |
| Google Chrome | Browser | |
| Microsoft Edge | Browser | |
| Brave Browser | Browser | |
| Firefox | Browser | |
| DuckDuckGo Browser | Browser | *Manual install — see note below* |
| Docker Desktop | Container | Docker container platform |
| Podman Desktop | Container | Podman container management |
| Obsidian | Editor | Knowledge management |
| Sublime Text | Editor | Lightweight text editor |
| iTerm2 | Terminal | Enhanced terminal emulator |
| Git | CLI | Version control |
| Git LFS | CLI | Git Large File Storage |
| cURL | CLI | HTTP client |
| HTTPie | CLI | Human-friendly HTTP client |
| Python 3.13 | Language | Python runtime |
| .NET SDK | Language | .NET development kit |
| OpenSSL 3 | Library | Cryptography toolkit |
| jq | CLI | JSON processor |
| draw.io | App | Diagramming tool |
| Coder | CLI | Remote development |

### Common Dev + DevOps Apps

| Application | Type | Description |
|-------------|------|-------------|
| AWS CLI | CLI | Amazon Web Services CLI |
| Azure CLI | CLI | Microsoft Azure CLI |
| Visual Studio Code | Editor | Code editor |
| Postman | App | API testing |
| DBeaver Community | App | Universal database tool |
| TablePlus | App | Database client |
| NVM | CLI | Node Version Manager (installs Node.js 24) |

### Common DevOps Apps

| Application | Type | Description |
|-------------|------|-------------|
| Google Cloud SDK | CLI | GCP command-line tools |
| kubectl | CLI | Kubernetes CLI |
| Helm | CLI | Kubernetes package manager |
| K9s | CLI | Kubernetes terminal dashboard |
| k6 | CLI | Load testing tool |
| Terraform | CLI | Infrastructure as Code |
| Ansible | CLI | Configuration management |

### COSMOS Apps

| Application | Type | Description |
|-------------|------|-------------|
| WebStorm | IDE | JavaScript/TypeScript IDE |

---

## Before You Begin

### Requirements

- **macOS 10.14 (Mojave) or later** — the script will check this automatically
- **Admin password** — you'll be prompted once during Homebrew installation
- **Internet connection** — required throughout the install
- **20 GB free disk space** — the script checks this before starting
- **30–60 minutes** — depending on your internet speed and how many apps are already installed

### Tips

- **Do NOT run as root** — the script will stop you if you try `sudo ./Cosmos_Deployment.sh`
- **Close other large downloads** — the script downloads several GB of software
- **Plug in your charger** — this takes a while on battery

---

## Step-by-Step Installation

### Step 1: Download the Script

Open **Terminal** (press `Cmd + Space`, type `Terminal`, press Enter) and run:

```bash
curl -fsSL -o ~/Desktop/Cosmos_Deployment.sh \
  "https://raw.githubusercontent.com/kmwhite40/mac-dev-setup.sh/main/packages/macos/mac-dev-setup/scripts/Cosmos_Deployment.sh"
```

This downloads the script to your Desktop.

### Step 2: Make It Executable

```bash
chmod +x ~/Desktop/Cosmos_Deployment.sh
```

### Step 3: Run the Script

```bash
~/Desktop/Cosmos_Deployment.sh
```

### Step 4: Follow the Prompts

1. The script will check your system (macOS version, internet, disk space)
2. **Xcode Command Line Tools** — if not installed, a dialog will pop up. Click **Install** and wait for it to finish
3. **Homebrew** — if not installed, you'll be asked for your **admin password** once
4. The script will then install all packages automatically — sit back and let it run
5. When complete, you'll see a **"Setup Complete"** banner with next steps

### What It Looks Like

```
=========================================
 COSMOS Deployment v1.0.0
=========================================
 Company: SBS Federal
 Support: it@sbsfederal.com

=========================================
 System Prerequisites Check
=========================================
 ✅ macOS version 15.4 is supported
 ✅ Internet connection verified
 ✅ Sufficient disk space available (87GB)

=========================================
 Installing Core Apps
=========================================
 ✅ Google Chrome is already installed
 Installing Microsoft Edge...
 ✅ Microsoft Edge installed successfully
 ...
```

---

## After Installation

### 1. Install DuckDuckGo Browser (Manual)

DuckDuckGo does not have a Homebrew installer. Download it directly:

1. Open Safari or any installed browser
2. Go to **https://duckduckgo.com/mac**
3. Click **Download** and drag the app to your Applications folder

### 2. Start Docker Desktop

Open **Docker Desktop** from your Applications folder. The first launch will complete additional setup.

### 3. Configure Git

Open a **new Terminal window** and run:

```bash
git config --global user.name "Your Full Name"
git config --global user.email "your.email@sbsfederal.com"
```

### 4. Set Up Node.js via NVM

Open a **new Terminal window** (important — NVM needs a fresh shell):

```bash
nvm install 24
nvm use 24
nvm alias default 24
```

Verify:

```bash
node --version   # Should show v24.x.x
npm --version
```

### 5. Authenticate Cloud CLIs

```bash
# AWS
aws configure

# Azure
az login

# Google Cloud
gcloud auth login
gcloud config set project <YOUR_PROJECT_ID>
```

### 6. Verify Everything Is Working

```bash
# Quick health check
brew doctor

# List installed formulae
brew list --formula

# List installed casks
brew list --cask
```

---

## Weekly Auto-Updates

The script automatically registers a **weekly update schedule** via macOS launchd:

- **When:** Every **Sunday at 10:00 AM**
- **What:** Updates Homebrew, upgrades all formulae and casks, cleans up old versions
- **Notification:** A macOS notification appears when the update completes (or if it fails)
- **Logs:** `~/Library/Logs/cosmos-deployment/weekly-update-*.log`

### Check the Latest Update Log

```bash
ls -t ~/Library/Logs/cosmos-deployment/weekly-update-*.log | head -1 | xargs cat
```

### Disable Auto-Updates

```bash
launchctl bootout gui/$(id -u)/com.sbsfederal.cosmos-deployment.weekly-update
```

### Re-Enable Auto-Updates

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.sbsfederal.cosmos-deployment.weekly-update.plist
```

### Run an Update Manually

```bash
bash ~/Library/Logs/cosmos-deployment/cosmos-weekly-update.sh
```

---

## Troubleshooting

### "Homebrew is not installed" error after reboot

Your shell may not have Homebrew in its PATH. Run:

```bash
# Apple Silicon Mac (M1/M2/M3/M4)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Mac
eval "$(/usr/local/bin/brew shellenv)"
```

Then open a new Terminal window.

### Xcode Command Line Tools dialog doesn't appear

Run manually:

```bash
xcode-select --install
```

### A specific app failed to install

Re-run just that one app. For example:

```bash
# Cask (GUI app)
brew install --cask postman

# Formula (CLI tool)
brew install terraform
```

### "Permission denied" errors

Make sure you're NOT running as root:

```bash
# Wrong
sudo ./Cosmos_Deployment.sh

# Correct
./Cosmos_Deployment.sh
```

### NVM says "command not found"

Open a **new Terminal window** — NVM is configured in your shell profile and only loads in new sessions. If it still doesn't work:

```bash
# Check if it's in your .zshrc
grep NVM ~/.zshrc

# If missing, add it manually
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"' >> ~/.zshrc
source ~/.zshrc
```

### Weekly update isn't running

```bash
# Check if the agent is loaded
launchctl list | grep cosmos

# View launchd stderr for errors
cat ~/Library/Logs/cosmos-deployment/launchd-stderr.log
```

### Script runs again — will it break anything?

No. The script is **idempotent** — it checks whether each package is already installed before trying to install it. Running it multiple times is completely safe.

---

## FAQ

**Q: How long does the full install take?**
A: First run takes 30–60 minutes depending on internet speed and how many apps are already installed. Subsequent runs are much faster since they skip already-installed packages.

**Q: Can I skip certain apps?**
A: Yes — edit the script and comment out (add `#` before) any `install_cask` or `install_formula` line you don't need.

**Q: Where are logs stored?**
A: All logs are in `~/Library/Logs/cosmos-deployment/`:
- `cosmos-deployment.log` — main install log
- `weekly-update-*.log` — timestamped weekly update logs
- `launchd-stdout.log` / `launchd-stderr.log` — launchd output

**Q: Can I run the script on an Intel Mac?**
A: Yes. The script auto-detects Apple Silicon vs. Intel and adjusts Homebrew paths accordingly. On Apple Silicon, it also installs Rosetta 2 for Intel-only apps.

**Q: How do I update a single app?**
A: Use Homebrew directly:
```bash
brew upgrade terraform         # CLI tool
brew upgrade --cask docker     # GUI app
```

**Q: Who do I contact for help?**
A: Email **it@sbsfederal.com** with the contents of your log file:
```bash
cat ~/Library/Logs/cosmos-deployment/cosmos-deployment.log
```

---

*COSMOS Deployment v1.0.0 — SBS Federal*
