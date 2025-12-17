# Mac Development Environment Setup Script

A comprehensive, automated setup script for macOS development environments with forced system updates, automatic application installation, and desktop shortcuts.

## Features

- **Automatic Homebrew Installation** - Installs Homebrew if not present
- **Forced System Updates** - Automatically updates macOS and packages every 4 days
- **Smart Installation** - Checks if applications are already installed before downloading
- **Desktop Shortcuts** - Creates convenient shortcuts for frequently used applications
- **Comprehensive Logging** - All operations logged to `~/.mac-dev-setup.log`
- **Error Handling** - Individual package failures don't stop the entire installation
- **Color-Coded Output** - Easy to read console output with status indicators

## What Gets Installed

### GUI Applications

| Application | Description |
|------------|-------------|
| Docker | Container platform |
| Podman | Alternative container platform |
| iTerm2 | Advanced terminal emulator |
| Visual Studio Code | Microsoft's code editor |
| Cursor | AI-powered code editor |
| IntelliJ IDEA CE | JetBrains Java IDE (Community Edition) |
| Obsidian | Knowledge base and note-taking app |
| Postman | API development and testing |
| pgAdmin4 | PostgreSQL administration tool |
| TablePlus | Database management tool |
| DBeaver | Universal database tool |
| MongoDB Compass | MongoDB GUI |
| GitHub Desktop | GitHub visual client |
| GitLab Desktop | GitLab visual client |

### CLI Tools

| Tool | Description |
|------|-------------|
| git | Version control system |
| gh | GitHub CLI |
| glab | GitLab CLI |
| maven | Java build tool |
| node | JavaScript runtime |
| python | Python programming language |
| openjdk | Java Development Kit |
| go | Go programming language |
| dotnet | .NET SDK |
| kubectl | Kubernetes CLI |
| helm | Kubernetes package manager |
| awscli | AWS command line interface |
| azure-cli | Azure command line interface |
| google-cloud-sdk | Google Cloud SDK |
| terraform | Infrastructure as code tool |
| ansible | IT automation tool |
| k9s | Kubernetes CLI manager |
| curl | Data transfer tool |
| httpie | HTTP client |
| k6 | Load testing tool |
| coder | Cloud development environments |

## Prerequisites

- macOS (tested on macOS 10.15+)
- Internet connection
- Administrator access (for system updates)

## Installation

### Quick Start

1. **Download the script:**
   ```bash
   git clone <repository-url>
   cd mac-dev-setup.sh
   ```

   Or download directly:
   ```bash
   curl -O https://your-repo-url/mac-dev-setup.sh
   ```

2. **Make the script executable:**
   ```bash
   chmod +x mac-dev-setup.sh
   ```

3. **Run the script:**
   ```bash
   ./mac-dev-setup.sh
   ```

### First-Time Setup

On your first run, the script will:
1. Install Homebrew (if not present)
2. Perform a full macOS system update
3. Install all applications and CLI tools
4. Create desktop shortcuts
5. Set up the 4-day update tracking

**Note:** You'll be prompted for your password for `sudo` operations during macOS system updates.

## Usage

### Running the Script

```bash
./mac-dev-setup.sh
```

The script will automatically:
- Check if 4 days have passed since the last update
- Update macOS and Homebrew if needed
- Install missing applications
- Skip already installed packages
- Create desktop shortcuts
- Log all operations

### Understanding the Update Cycle

The script uses a timestamp file (`~/.mac-dev-setup-last-update`) to track updates:

- **First run**: Full system update + install all packages
- **Within 4 days**: Only update Homebrew, install missing packages
- **After 4 days**: Full system update + Homebrew update + install missing packages

### Customizing Update Interval

Edit the script and change this line:

```bash
UPDATE_INTERVAL_DAYS=4
```

Change `4` to your desired number of days.

## Configuration

### Adding New Applications

To add a new GUI application:

```bash
install_cask "application-name"
```

To add a new CLI tool:

```bash
install_formula "tool-name"
```

Find package names at [Homebrew Formulae](https://formulae.brew.sh/)

### Customizing Desktop Shortcuts

Edit the `create_desktop_shortcuts()` function around line 145:

```bash
declare -A apps=(
    ["App Name"]="/Applications/App Name.app"
    # Add more apps here
)
```

## Post-Installation Steps

After the script completes, follow these steps:

### 1. Authenticate GitHub CLI

```bash
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

Set up git credential helper:
```bash
gh auth setup-git
```

### 2. Authenticate GitLab CLI

```bash
glab auth login
```

Follow the prompts to authenticate with your GitLab account.

### 3. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Start Docker

Launch Docker Desktop from:
- Applications folder
- Desktop shortcut
- Spotlight (Cmd + Space, type "Docker")

### 5. Configure IDEs

- **VS Code**: Open and install extensions
- **Cursor**: Open and authenticate with API key
- **IntelliJ IDEA**: Configure JDK and plugins

### 6. Verify Installations

```bash
# Check versions
node --version
python3 --version
git --version
kubectl version --client
terraform --version

# Check Homebrew health
brew doctor
```

## Log Files

### View Installation Log

```bash
cat ~/.mac-dev-setup.log
```

### View Last 50 Lines

```bash
tail -50 ~/.mac-dev-setup.log
```

### Search Log for Errors

```bash
grep "❌" ~/.mac-dev-setup.log
```

## Troubleshooting

### Script Fails with Permission Denied

Make sure the script is executable:
```bash
chmod +x mac-dev-setup.sh
```

### Homebrew Installation Fails

Manually install Homebrew first:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then run the script again.

### Application Installation Fails

Check the log file for specific errors:
```bash
grep "Failed to install" ~/.mac-dev-setup.log
```

Manually install the failed package:
```bash
brew install --cask application-name
# or
brew install tool-name
```

### System Update Hangs

macOS updates can take a while. If it appears stuck:
1. Wait at least 30 minutes
2. Check Activity Monitor for `softwareupdate` process
3. Cancel with Ctrl+C and run again later

### Desktop Shortcuts Not Created

Run this command manually:
```bash
ln -s "/Applications/Cursor.app" "$HOME/Desktop/Cursor"
```

Replace `Cursor` with the desired application name.

### Force Update Before 4 Days

Delete the timestamp file:
```bash
rm ~/.mac-dev-setup-last-update
./mac-dev-setup.sh
```

## Advanced Usage

### Run Without System Updates

Comment out the update function call in the script (lines 210-216):

```bash
# if should_update_system; then
#     log_warning "Forced system update required..."
#     update_macos_system
#     update_homebrew
#     mark_update_complete
# else
    update_homebrew
# fi
```

### Dry Run (Check What Would Be Installed)

```bash
# Check which casks would be installed
brew install --cask --dry-run docker

# Check which formulas would be installed
brew install --dry-run git
```

### Batch Update All Existing Packages

```bash
brew update
brew upgrade
brew cleanup
```

### Uninstall an Application

```bash
# GUI application
brew uninstall --cask application-name

# CLI tool
brew uninstall tool-name
```

## Automation

### Run Script on Schedule with Launchd

1. Create a plist file:

```bash
cat > ~/Library/LaunchAgents/com.user.mac-dev-setup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.mac-dev-setup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/mac-dev-setup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
EOF
```

2. Load the launch agent:

```bash
launchctl load ~/Library/LaunchAgents/com.user.mac-dev-setup.plist
```

This will run the script daily at 9:00 AM. The script's internal 4-day check will determine if updates are needed.

### Run Script via Cron

```bash
# Edit crontab
crontab -e

# Add this line (runs daily at 9 AM)
0 9 * * * /path/to/mac-dev-setup.sh >> ~/mac-dev-setup-cron.log 2>&1
```

## Security Considerations

- The script requires `sudo` access for macOS system updates
- Review the script contents before running
- All packages are installed from official Homebrew repositories
- GitHub and GitLab authentication is manual (script doesn't handle credentials)

## File Locations

| File | Purpose |
|------|---------|
| `~/.mac-dev-setup.log` | Installation and update log |
| `~/.mac-dev-setup-last-update` | Timestamp of last system update |
| `~/Desktop/*` | Application shortcuts |
| `/Applications/*.app` | Installed applications |
| `/usr/local/bin/*` or `/opt/homebrew/bin/*` | CLI tools |

## FAQ

**Q: Can I run this script multiple times?**
A: Yes! The script checks if packages are already installed and skips them.

**Q: Will this overwrite my existing configurations?**
A: No. The script only installs applications and tools. It doesn't modify existing configurations.

**Q: Can I customize which apps get installed?**
A: Yes. Edit the script and comment out (add `#` before) any lines you don't want.

**Q: How do I stop the forced updates?**
A: Set `UPDATE_INTERVAL_DAYS` to a very high number (e.g., 365) or comment out the update check.

**Q: What if I'm on Apple Silicon (M1/M2/M3)?**
A: The script automatically detects Apple Silicon and configures Homebrew correctly.

**Q: Can I install additional packages later?**
A: Yes! Either add them to the script or install manually with `brew install`.

## Maintenance

### Keep Script Updated

```bash
cd mac-dev-setup.sh
git pull origin main
```

### Check for Outdated Packages

```bash
brew outdated
```

### Upgrade All Packages Manually

```bash
brew update
brew upgrade
brew cleanup
```

### Remove Unused Dependencies

```bash
brew autoremove
```

## Contributing

To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This script is provided as-is for personal and commercial use.

## Support

For issues or questions:
- Check the log file: `~/.mac-dev-setup.log`
- Review troubleshooting section above
- Check Homebrew documentation: https://docs.brew.sh/

## Changelog

### Version 2.0
- Added forced system updates every 4 days
- Added automatic Homebrew installation
- Added GitHub/GitLab CLI and Desktop apps
- Added Cursor AI editor
- Added desktop shortcuts creation
- Added comprehensive logging
- Added error handling for individual packages
- Added color-coded output

### Version 1.0
- Initial release with basic package installation

---

**Last Updated:** 2025-12-17
