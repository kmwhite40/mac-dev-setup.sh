#!/bin/bash
# =============================================================================
# update-brew.sh — Unattended Homebrew update with timestamped logging
# =============================================================================
#
# Designed to run from launchd or cron. Performs a full update cycle:
#   1. Update Homebrew metadata
#   2. Upgrade all installed formulae and casks
#   3. Clean up old versions
#
# All output is written to a timestamped log file.
# On failure, optionally sends a macOS notification.
#
# Usage:
#   ./scripts/update-brew.sh              # Normal unattended run
#   ./scripts/update-brew.sh --notify     # Send macOS notification on finish
#   ./scripts/update-brew.sh --dry-run    # Preview without changes
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

LOG_DIR="$HOME/Library/Logs/brew-deploy-agent"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$LOG_DIR/update-$TIMESTAMP.log"

DRY_RUN=false
NOTIFY=false
EXIT_CODE=0

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --notify)  NOTIFY=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--notify]"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Logging & notifications
# ---------------------------------------------------------------------------

mkdir -p "$LOG_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
}

log_ok()  { log "OK    $1"; }
log_err() { log "ERROR $1"; }

notify() {
    if $NOTIFY; then
        osascript -e "display notification \"$1\" with title \"brew-deploy-agent\"" 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Ensure Homebrew is on PATH
# ---------------------------------------------------------------------------

if [[ "$(uname -m)" == "arm64" ]]; then
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    log_err "Homebrew not found. Aborting."
    notify "Update failed: Homebrew not found."
    exit 1
fi

# ---------------------------------------------------------------------------
# Run update cycle
# ---------------------------------------------------------------------------

log "=== update-brew.sh started ==="
log "Homebrew: $(brew --version | head -1)"
log "Dry run:  $DRY_RUN"

# Step 1: Update metadata
log "Updating Homebrew metadata..."
if $DRY_RUN; then
    log "DRY RUN: skipping brew update"
else
    if brew update >> "$LOG_FILE" 2>&1; then
        log_ok "Metadata updated."
    else
        log_err "brew update failed."
        EXIT_CODE=1
    fi
fi

# Step 2: Upgrade formulae
log "Upgrading formulae..."
if $DRY_RUN; then
    log "DRY RUN: outdated formulae:"
    brew outdated >> "$LOG_FILE" 2>&1 || true
else
    if brew upgrade >> "$LOG_FILE" 2>&1; then
        log_ok "Formulae upgraded."
    else
        log_err "Some formulae failed to upgrade."
        EXIT_CODE=1
    fi
fi

# Step 3: Upgrade casks
log "Upgrading casks..."
if $DRY_RUN; then
    log "DRY RUN: outdated casks:"
    brew outdated --cask >> "$LOG_FILE" 2>&1 || true
else
    if brew upgrade --cask --greedy >> "$LOG_FILE" 2>&1; then
        log_ok "Casks upgraded."
    else
        log_err "Some casks failed to upgrade."
        EXIT_CODE=1
    fi
fi

# Step 4: Cleanup
log "Cleaning up..."
if ! $DRY_RUN; then
    brew cleanup >> "$LOG_FILE" 2>&1
    log_ok "Cleanup completed."
fi

# ---------------------------------------------------------------------------
# Prune old log files (keep last 30 days)
# ---------------------------------------------------------------------------

find "$LOG_DIR" -name "update-*.log" -mtime +30 -delete 2>/dev/null || true

# ---------------------------------------------------------------------------
# Finish
# ---------------------------------------------------------------------------

if [[ $EXIT_CODE -eq 0 ]]; then
    log_ok "update-brew.sh finished successfully."
    notify "Homebrew update completed successfully."
else
    log_err "update-brew.sh finished with errors. Check: $LOG_FILE"
    notify "Homebrew update finished with errors."
fi

exit $EXIT_CODE
