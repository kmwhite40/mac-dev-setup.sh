# Operations and Execution Flow

This document describes the complete execution flow of the Mac Dev Setup script.

## Execution Flow Diagram

```
┌─────────────────────────────────────┐
│     Start: ./mac-dev-setup.sh      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Initialize Logging & Colors       │
│   - Set up log file                 │
│   - Configure color output          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Check Running as Root?            │
│   (EUID == 0)                       │
└──────────────┬──────────────────────┘
               │
         ┌─────┴─────┐
         │           │
        Yes          No
         │           │
         ▼           ▼
    ┌────────┐  ┌─────────────────────┐
    │  EXIT  │  │  Continue           │
    │ Error  │  └──────────┬──────────┘
    └────────┘             │
                           ▼
              ┌─────────────────────────────┐
              │  Is Homebrew Installed?     │
              │  (command -v brew)          │
              └──────────┬──────────────────┘
                         │
                   ┌─────┴─────┐
                   │           │
                  Yes          No
                   │           │
                   │           ▼
                   │    ┌──────────────────┐
                   │    │ Install Homebrew │
                   │    │ - Download       │
                   │    │ - Configure PATH │
                   │    └─────────┬────────┘
                   │              │
                   └──────┬───────┘
                          │
                          ▼
              ┌────────────────────────────┐
              │ Check Update Timestamp     │
              │ Read: ~/.mac-dev-setup-    │
              │       last-update          │
              └──────────┬─────────────────┘
                         │
                   ┌─────┴─────┐
                   │           │
            File Exists    No File
                   │           │
                   │           └──────┐
                   ▼                  │
         ┌──────────────────┐        │
         │ Calculate Days   │        │
         │ Since Last       │        │
         │ Update           │        │
         └────────┬─────────┘        │
                  │                  │
            ┌─────┴─────┐            │
            │           │            │
        >= 4 Days    < 4 Days        │
            │           │            │
            └─────┬─────┘            │
                  │                  │
          ┌───────┴────────┐         │
          │                │         │
         Yes               No        │
          │                │         │
          ▼                ▼         ▼
┌──────────────────┐  ┌─────────────────────┐
│ FULL UPDATE      │  │ PARTIAL UPDATE      │
│ ================ │  │ ===============     │
│ 1. macOS Update  │  │ 1. Skip macOS       │
│    - Check       │  │ 2. Homebrew Update  │
│    - Download    │  │    - brew update    │
│    - Install     │  │    - brew upgrade   │
│    - Restart?    │  │    - brew cleanup   │
│ 2. Homebrew      │  └──────────┬──────────┘
│    - brew update │             │
│    - brew upgrade│             │
│    - brew cleanup│             │
│ 3. Mark Complete │             │
└─────────┬────────┘             │
          │                      │
          └──────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  Install GUI Applications  │
        │  ========================  │
        │  For each app:             │
        │    - Check if installed    │
        │    - Skip if present       │
        │    - Install if missing    │
        │    - Log result            │
        │  ------------------------  │
        │  Apps:                     │
        │  • Docker                  │
        │  • Podman                  │
        │  • iTerm2                  │
        │  • VS Code                 │
        │  • Cursor                  │
        │  • IntelliJ IDEA CE        │
        │  • Obsidian                │
        │  • Postman                 │
        │  • pgAdmin4                │
        │  • TablePlus               │
        │  • DBeaver                 │
        │  • MongoDB Compass         │
        │  • GitHub Desktop          │
        │  • GitLab Desktop          │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │   Install CLI Tools        │
        │   =====================    │
        │   For each tool:           │
        │     - Check if installed   │
        │     - Skip if present      │
        │     - Install if missing   │
        │     - Log result           │
        │   ---------------------    │
        │   Tools:                   │
        │   • git, gh, glab          │
        │   • maven, node, python    │
        │   • openjdk, go, dotnet    │
        │   • kubectl, helm          │
        │   • awscli, azure-cli      │
        │   • google-cloud-sdk       │
        │   • terraform, ansible     │
        │   • k9s, curl, httpie      │
        │   • k6, coder              │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │  Create Desktop Shortcuts  │
        │  ========================  │
        │  For each app:             │
        │    - Check app exists      │
        │    - Check shortcut exists │
        │    - Create symlink        │
        │    - Log result            │
        │  ------------------------  │
        │  Shortcuts:                │
        │  • Cursor                  │
        │  • VS Code                 │
        │  • iTerm                   │
        │  • Docker                  │
        │  • Postman                 │
        │  • GitHub Desktop          │
        │  • IntelliJ IDEA CE        │
        │  • Obsidian                │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │  Configure CLI Tools       │
        │  =====================     │
        │  • Display gh auth info    │
        │  • Display glab auth info  │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │  Final Cleanup             │
        │  =============             │
        │  • brew cleanup            │
        │  • brew doctor             │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │  Display Summary           │
        │  ===============           │
        │  • Success message         │
        │  • Log file location       │
        │  • Next update date        │
        │  • Next steps              │
        └─────────────┬──────────────┘
                      │
                      ▼
              ┌───────────────┐
              │   Complete    │
              │   Exit 0      │
              └───────────────┘
```

## Detailed Operations

### Phase 1: Initialization

```bash
# What happens
- Load configuration variables
- Initialize logging functions
- Set up color codes
- Create log file if needed

# Files affected
- ~/.mac-dev-setup.log (created/appended)

# Time: < 1 second
```

### Phase 2: Security Check

```bash
# What happens
- Check if running as root (EUID == 0)
- Exit if running with sudo

# Why
- Script should run as regular user
- sudo only used when needed for system updates

# Time: < 1 second
```

### Phase 3: Homebrew Installation

```bash
# What happens
IF Homebrew not installed:
  - Download Homebrew install script
  - Run installation
  - Configure PATH (especially for Apple Silicon)
  - Verify installation
ELSE:
  - Log that Homebrew is present
  - Continue

# Files affected
- /opt/homebrew/* (Apple Silicon)
- /usr/local/Homebrew/* (Intel)
- ~/.zprofile (PATH configuration)

# Time: 2-5 minutes (if installing), < 1 second (if present)
```

### Phase 4: Update Check

```bash
# What happens
1. Read ~/.mac-dev-setup-last-update
2. Get current timestamp
3. Calculate days since last update
4. IF >= 4 days OR no file:
     - Run full system update
   ELSE:
     - Run Homebrew update only

# Files affected
- ~/.mac-dev-setup-last-update (read/write)

# Time: < 1 second
```

### Phase 5: System Updates (Every 4 Days)

```bash
# What happens
1. macOS Update:
   - Run: softwareupdate -l
   - Check for available updates
   - Install: sudo softwareupdate -ia --verbose
   - Prompt for restart if needed

2. Homebrew Update:
   - brew update (update package lists)
   - brew upgrade (upgrade installed packages)
   - brew cleanup (remove old versions)

3. Mark Complete:
   - Write current timestamp to file

# Requires
- sudo password for macOS updates
- Internet connection

# Time: 5-30 minutes (depends on updates available)
```

### Phase 6: Application Installation

```bash
# What happens
For each GUI application:
  1. Check: brew list --cask "app-name"
  2. IF installed:
       - Log: "already installed"
       - Skip
     ELSE:
       - Run: brew install --cask "app-name"
       - Log success or failure
       - Continue to next

# Behavior
- Individual failures don't stop script
- Already installed apps are skipped
- Downloads happen in parallel where possible

# Time: 15-45 minutes total (first run), < 1 minute (subsequent runs)
```

### Phase 7: CLI Tools Installation

```bash
# What happens
For each CLI tool:
  1. Check: brew list "tool-name"
  2. IF installed:
       - Log: "already installed"
       - Skip
     ELSE:
       - Run: brew install "tool-name"
       - Log success or failure
       - Continue to next

# Behavior
- Same as GUI applications
- Individual failures don't stop script
- Parallel downloads where possible

# Time: 10-30 minutes total (first run), < 1 minute (subsequent runs)
```

### Phase 8: Desktop Shortcuts

```bash
# What happens
For each application:
  1. Check if app exists in /Applications/
  2. IF exists:
       - Check if shortcut already exists
       - IF not exists:
           - Create symlink: ln -s
           - Log success
       ELSE:
           - Log already exists
     ELSE:
       - Log warning (app not found)

# Files created
- ~/Desktop/Cursor -> /Applications/Cursor.app
- ~/Desktop/Visual Studio Code -> /Applications/Visual Studio Code.app
- ~/Desktop/iTerm -> /Applications/iTerm.app
- ~/Desktop/Docker -> /Applications/Docker.app
- ~/Desktop/Postman -> /Applications/Postman.app
- ~/Desktop/GitHub Desktop -> /Applications/GitHub Desktop.app
- ~/Desktop/IntelliJ IDEA CE -> /Applications/IntelliJ IDEA CE.app
- ~/Desktop/Obsidian -> /Applications/Obsidian.app

# Time: < 1 second
```

### Phase 9: CLI Configuration

```bash
# What happens
1. Check if 'gh' command exists
   - Display authentication instructions

2. Check if 'glab' command exists
   - Display authentication instructions

# Note
- Does NOT automatically authenticate
- User must run commands manually after script
- This is for security (no credential handling)

# Time: < 1 second
```

### Phase 10: Cleanup & Summary

```bash
# What happens
1. Run: brew cleanup
   - Remove old package versions
   - Free up disk space

2. Run: brew doctor
   - Check for issues
   - Non-critical warnings logged

3. Display summary:
   - Success message
   - Log file location
   - Next update date
   - Next steps instructions

# Time: 1-2 minutes
```

## Error Handling

### Individual Package Failures

```bash
# Behavior
- Script continues even if one package fails
- Error is logged with ❌ symbol
- Check log for specific failures

# Example
install_cask "app" && log_success "installed" || log_error "failed"
```

### System Update Failures

```bash
# Behavior
- set -e causes script to exit on error
- BUT: brew doctor is allowed to fail
- System updates require sudo password

# Recovery
- Re-run script after fixing issue
- Script picks up where it left off
```

### Network Issues

```bash
# Behavior
- Homebrew will retry downloads
- Timeout after reasonable period
- Error logged and installation continues

# Recovery
- Re-run script when network is stable
- Only missing packages will be installed
```

## File System Changes

### Created Files

| Location | Purpose | Size |
|----------|---------|------|
| `~/.mac-dev-setup.log` | Installation log | Grows over time (~1-10 MB) |
| `~/.mac-dev-setup-last-update` | Update timestamp | < 1 KB |
| `~/Desktop/*` | Application shortcuts | 0 bytes (symlinks) |

### Installed Locations

| Path | Contents |
|------|----------|
| `/Applications/*.app` | GUI applications |
| `/opt/homebrew/*` or `/usr/local/*` | Homebrew and CLI tools |
| `~/.zprofile` | Shell configuration (PATH) |

## Performance Characteristics

### First Run
- **Total Time:** 45-90 minutes
- **Disk Space:** ~20-30 GB
- **Network Usage:** ~10-15 GB download

### Subsequent Runs (< 4 days)
- **Total Time:** 2-10 minutes
- **Disk Space:** Minimal (only new packages)
- **Network Usage:** < 1 GB

### Update Runs (>= 4 days)
- **Total Time:** 15-45 minutes
- **Disk Space:** ~1-5 GB
- **Network Usage:** ~2-5 GB

## Monitoring Execution

### Real-Time Log Watching

```bash
# Terminal 1: Run script
./mac-dev-setup.sh

# Terminal 2: Watch log
tail -f ~/.mac-dev-setup.log
```

### Check Progress

```bash
# Count installed apps
brew list --cask | wc -l

# Count installed tools
brew list --formula | wc -l

# Check current operation
ps aux | grep brew
```

### Debug Mode

```bash
# Run with verbose output
bash -x ./mac-dev-setup.sh
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (running as root, or critical failure) |

## Next Steps After Execution

See [QUICK_START.md](QUICK_START.md) for post-installation steps.

---

**Document Version:** 1.0
**Last Updated:** 2025-12-17
