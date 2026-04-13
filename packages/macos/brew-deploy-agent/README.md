# brew-deploy-agent

A macOS script-based deployment agent that uses Homebrew for declarative software installation and automatic daily updates.

## Directory Structure

```
brew-deploy-agent/
├── Brewfile                          # Default package list
├── README.md
├── profiles/
│   ├── Brewfile.base                 # Minimal — every machine
│   ├── Brewfile.dev                  # Developer workstation
│   └── Brewfile.design               # Design team
├── launchd/
│   └── com.brew-deploy-agent.update.plist   # launchd template
└── scripts/
    ├── bootstrap.sh                  # First-run setup
    ├── deploy.sh                     # Install, upgrade, cleanup
    ├── update-brew.sh                # Unattended update (launchd target)
    └── install-launchagent.sh        # Register the launchd agent
```

## Quick Start

```bash
# 1. Clone or copy this directory to the target Mac

# 2. Make scripts executable
chmod +x scripts/*.sh

# 3. Run bootstrap (installs Homebrew + packages from the default Brewfile)
./scripts/bootstrap.sh

# 4. Enable daily automatic updates
./scripts/install-launchagent.sh
```

## How to Install

### First-time setup

`bootstrap.sh` handles everything from scratch:

- Installs Xcode Command Line Tools if missing
- Installs Rosetta 2 on Apple Silicon
- Installs Homebrew if missing
- Runs `brew bundle` against the selected Brewfile

```bash
# Default Brewfile
./scripts/bootstrap.sh

# With a profile
./scripts/bootstrap.sh --profile dev

# Preview without installing
./scripts/bootstrap.sh --dry-run
```

### Ongoing deployments

`deploy.sh` is for subsequent runs — it updates Homebrew, installs missing packages, upgrades existing ones, and cleans up:

```bash
./scripts/deploy.sh

# With a specific profile
./scripts/deploy.sh --profile dev

# Install missing only, skip upgrades
./scripts/deploy.sh --no-upgrade

# Send a macOS notification when done
./scripts/deploy.sh --notify

# Dry run
./scripts/deploy.sh --dry-run
```

## Customizing the Brewfile

Edit the `Brewfile` (or a profile under `profiles/`) using standard [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle) syntax:

```ruby
# Taps
tap "homebrew/bundle"

# CLI tools (formulae)
brew "git"
brew "node"

# GUI applications (casks)
cask "visual-studio-code"
cask "docker"

# Mac App Store apps (requires 'mas' formula)
# mas "Xcode", id: 497799835
```

### Machine profiles

Use `--profile <name>` to target a specific Brewfile under `profiles/`:

| Profile  | File                      | Purpose                  |
|----------|---------------------------|--------------------------|
| `base`   | `profiles/Brewfile.base`  | Core tools for every Mac |
| `dev`    | `profiles/Brewfile.dev`   | Developer workstation    |
| `design` | `profiles/Brewfile.design`| Design team              |

Profiles are additive — run `base` first, then your role-specific profile:

```bash
./scripts/deploy.sh --profile base
./scripts/deploy.sh --profile dev
```

To add a new profile, create `profiles/Brewfile.<name>` and reference it with `--profile <name>`.

## Scheduled Updates

### Enable

```bash
./scripts/install-launchagent.sh
```

This registers a launchd agent that runs `update-brew.sh --notify` every day at 11:00 AM. If the Mac was asleep at 11:00, launchd will run it at the next wake.

### Disable

```bash
./scripts/install-launchagent.sh --uninstall
```

### Manual trigger

```bash
# Run the update script directly
./scripts/update-brew.sh

# With notification
./scripts/update-brew.sh --notify

# Dry run
./scripts/update-brew.sh --dry-run
```

## Logs

All logs are stored under:

```
~/Library/Logs/brew-deploy-agent/
```

| File pattern         | Source                          |
|----------------------|---------------------------------|
| `bootstrap.log`      | `bootstrap.sh`                 |
| `deploy-*.log`       | `deploy.sh` (timestamped)      |
| `update-*.log`       | `update-brew.sh` (timestamped) |
| `launchd-stdout.log` | launchd standard output        |
| `launchd-stderr.log` | launchd standard error          |

Update logs older than 30 days are automatically pruned.

View the latest update log:

```bash
ls -t ~/Library/Logs/brew-deploy-agent/update-*.log | head -1 | xargs cat
```

## Testing Scripts Manually

```bash
# Validate bootstrap without installing anything
./scripts/bootstrap.sh --dry-run

# Check what deploy would do
./scripts/deploy.sh --dry-run

# Run an update cycle without making changes
./scripts/update-brew.sh --dry-run

# Verify the launchd agent is registered
launchctl list | grep brew-deploy
```

## Design Principles

- **Idempotent**: Every script is safe to run multiple times.
- **Declarative**: Packages are defined in Brewfiles, not inline in scripts.
- **Non-destructive**: Scripts install and upgrade — they never remove packages you added manually.
- **Strict shell**: All scripts use `set -euo pipefail` to fail fast on errors.
- **Logged**: Every action is timestamped and written to a log file under `~/Library/Logs/`.
- **No root required**: Homebrew and launchd agents run as the current user.
