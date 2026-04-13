#!/bin/bash
# =============================================================================
# deploy.sh — Install missing packages, upgrade existing, and clean up
# =============================================================================
#
# This script is the primary deployment entrypoint after initial bootstrap.
# It updates Homebrew metadata, installs any missing packages from the
# Brewfile, upgrades already-installed packages, and cleans up old versions.
#
# Usage:
#   ./scripts/deploy.sh                       # Use default Brewfile
#   ./scripts/deploy.sh --profile dev          # Use profiles/Brewfile.dev
#   ./scripts/deploy.sh --dry-run              # Preview without changes
#   ./scripts/deploy.sh --no-upgrade           # Install missing only, skip upgrades
#   ./scripts/deploy.sh --notify               # Send macOS notification on finish
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$HOME/Library/Logs/brew-deploy-agent"
LOG_FILE="$LOG_DIR/deploy-$(date '+%Y%m%d-%H%M%S').log"

PROFILE=""
DRY_RUN=false
NO_UPGRADE=false
NOTIFY=false
EXIT_CODE=0

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)    PROFILE="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --no-upgrade) NO_UPGRADE=true; shift ;;
        --notify)     NOTIFY=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--profile <name>] [--dry-run] [--no-upgrade] [--notify]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve Brewfile
# ---------------------------------------------------------------------------

if [[ -n "$PROFILE" ]]; then
    BREWFILE="$PROJECT_DIR/profiles/Brewfile.$PROFILE"
else
    BREWFILE="$PROJECT_DIR/Brewfile"
fi

if [[ ! -f "$BREWFILE" ]]; then
    echo "ERROR: Brewfile not found: $BREWFILE" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Logging & notifications
# ---------------------------------------------------------------------------

mkdir -p "$LOG_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_ok()  { log "OK    $1"; }
log_err() { log "ERROR $1"; }

notify() {
    if $NOTIFY; then
        osascript -e "display notification \"$1\" with title \"brew-deploy-agent\"" 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

log "=== deploy.sh started ==="
log "Brewfile:    $BREWFILE"
log "Dry run:     $DRY_RUN"
log "No upgrade:  $NO_UPGRADE"

# Ensure Homebrew is available
if [[ "$(uname -m)" == "arm64" ]]; then
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    log_err "Homebrew is not installed. Run bootstrap.sh first."
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 1: Update Homebrew metadata
# ---------------------------------------------------------------------------

log "Updating Homebrew metadata..."

if $DRY_RUN; then
    log "DRY RUN: would run 'brew update'"
else
    if brew update 2>&1 | tee -a "$LOG_FILE"; then
        log_ok "Homebrew metadata updated."
    else
        log_err "brew update failed — continuing anyway."
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: Install missing packages from Brewfile
# ---------------------------------------------------------------------------

log "Checking packages from $BREWFILE ..."

if $DRY_RUN; then
    log "DRY RUN: checking which packages are missing..."
    brew bundle check --file="$BREWFILE" --verbose 2>&1 | tee -a "$LOG_FILE" || true
else
    if brew bundle check --file="$BREWFILE" &>/dev/null; then
        log_ok "All packages are already installed."
    else
        log "Installing missing packages..."
        if brew bundle install --file="$BREWFILE" 2>&1 | tee -a "$LOG_FILE"; then
            log_ok "Package installation completed."
        else
            log_err "Some packages failed to install — see log for details."
            EXIT_CODE=1
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Step 3: Upgrade installed packages
# ---------------------------------------------------------------------------

if ! $NO_UPGRADE; then
    log "Upgrading installed formulae..."

    if $DRY_RUN; then
        log "DRY RUN: would run 'brew upgrade'"
        brew outdated 2>&1 | tee -a "$LOG_FILE" || true
    else
        if brew upgrade 2>&1 | tee -a "$LOG_FILE"; then
            log_ok "Formulae upgraded."
        else
            log_err "Some formulae failed to upgrade."
            EXIT_CODE=1
        fi

        log "Upgrading installed casks..."
        if brew upgrade --cask --greedy 2>&1 | tee -a "$LOG_FILE"; then
            log_ok "Casks upgraded."
        else
            log_err "Some casks failed to upgrade."
            EXIT_CODE=1
        fi
    fi
else
    log "Skipping upgrades (--no-upgrade)."
fi

# ---------------------------------------------------------------------------
# Step 4: Cleanup
# ---------------------------------------------------------------------------

log "Cleaning up old versions and cache..."

if $DRY_RUN; then
    log "DRY RUN: would run 'brew cleanup --dry-run'"
    brew cleanup --dry-run 2>&1 | tee -a "$LOG_FILE" || true
else
    brew cleanup 2>&1 | tee -a "$LOG_FILE"
    log_ok "Cleanup completed."
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

if [[ $EXIT_CODE -eq 0 ]]; then
    log_ok "deploy.sh finished successfully."
    notify "Deployment completed successfully."
else
    log_err "deploy.sh finished with errors. Check: $LOG_FILE"
    notify "Deployment finished with errors. Check logs."
fi

log "Log: $LOG_FILE"
exit $EXIT_CODE
