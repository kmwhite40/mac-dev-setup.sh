#!/bin/bash
# =============================================================================
# bootstrap.sh — First-run setup for brew-deploy-agent
# =============================================================================
#
# Ensures Homebrew is installed, then runs brew bundle against the Brewfile.
# Safe to rerun — all operations are idempotent.
#
# Usage:
#   ./scripts/bootstrap.sh                      # Use default Brewfile
#   ./scripts/bootstrap.sh --profile dev         # Use profiles/Brewfile.dev
#   ./scripts/bootstrap.sh --dry-run             # Preview without installing
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$HOME/Library/Logs/brew-deploy-agent"
LOG_FILE="$LOG_DIR/bootstrap.log"

PROFILE=""
DRY_RUN=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--profile <base|dev|design>] [--dry-run]"
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
# Logging
# ---------------------------------------------------------------------------

mkdir -p "$LOG_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_ok() { log "OK    $1"; }
log_err() { log "ERROR $1"; }

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------

log "=== bootstrap.sh started ==="
log "Brewfile: $BREWFILE"
log "Dry run:  $DRY_RUN"

# Must not run as root — Homebrew refuses it.
if [[ "$EUID" -eq 0 ]]; then
    log_err "Do not run this script as root or with sudo."
    exit 1
fi

# Require macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_err "This script only runs on macOS."
    exit 1
fi

# ---------------------------------------------------------------------------
# Ensure Xcode Command Line Tools are present
# ---------------------------------------------------------------------------

if ! xcode-select -p &>/dev/null; then
    log "Xcode Command Line Tools not found. Installing..."
    xcode-select --install 2>&1 || true
    log "Waiting for Xcode CLT installation (this may open a dialog)..."

    _timeout=600
    _elapsed=0
    while ! xcode-select -p &>/dev/null; do
        sleep 10
        _elapsed=$((_elapsed + 10))
        if [[ $_elapsed -ge $_timeout ]]; then
            log_err "Xcode CLT installation timed out after ${_timeout}s."
            exit 1
        fi
    done
    log_ok "Xcode Command Line Tools installed."
else
    log_ok "Xcode Command Line Tools present."
fi

# ---------------------------------------------------------------------------
# Ensure Homebrew is installed
# ---------------------------------------------------------------------------

eval_brew_env() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
    fi
}

eval_brew_env

if command -v brew &>/dev/null; then
    log_ok "Homebrew already installed: $(brew --version | head -1)"
else
    log "Homebrew not found. Installing..."

    if $DRY_RUN; then
        log "DRY RUN: would install Homebrew"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval_brew_env

        if ! command -v brew &>/dev/null; then
            log_err "Homebrew installation failed."
            exit 1
        fi
        log_ok "Homebrew installed: $(brew --version | head -1)"
    fi
fi

# ---------------------------------------------------------------------------
# Install Rosetta 2 on Apple Silicon (required by some casks)
# ---------------------------------------------------------------------------

if [[ "$(uname -m)" == "arm64" ]]; then
    if ! /usr/bin/pgrep -q oahd && [[ ! -f /Library/Apple/usr/share/rosetta/rosetta ]]; then
        log "Installing Rosetta 2..."
        if ! $DRY_RUN; then
            softwareupdate --install-rosetta --agree-to-license 2>&1 | tee -a "$LOG_FILE"
        else
            log "DRY RUN: would install Rosetta 2"
        fi
    else
        log_ok "Rosetta 2 present."
    fi
fi

# ---------------------------------------------------------------------------
# Run brew bundle
# ---------------------------------------------------------------------------

log "Running brew bundle against $BREWFILE ..."

if $DRY_RUN; then
    log "DRY RUN: would run 'brew bundle check --file=$BREWFILE'"
    brew bundle check --file="$BREWFILE" 2>&1 | tee -a "$LOG_FILE" || true
    log "DRY RUN: the packages above would be installed."
else
    if brew bundle check --file="$BREWFILE" &>/dev/null; then
        log_ok "All packages from $BREWFILE are already installed."
    else
        log "Installing packages..."
        if brew bundle install --file="$BREWFILE" 2>&1 | tee -a "$LOG_FILE"; then
            log_ok "brew bundle completed successfully."
        else
            log_err "brew bundle finished with errors — check log for details."
            exit 1
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

log_ok "bootstrap.sh finished."
log "Log: $LOG_FILE"
