#!/bin/bash
# =============================================================================
# install-launchagent.sh — Install and load the launchd update agent
# =============================================================================
#
# Copies the plist into ~/Library/LaunchAgents and loads it with launchctl.
# Safe to rerun — unloads the existing agent before reloading.
#
# Usage:
#   ./scripts/install-launchagent.sh             # Install and load
#   ./scripts/install-launchagent.sh --uninstall  # Unload and remove
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PLIST_NAME="com.brew-deploy-agent.update.plist"
PLIST_SRC="$PROJECT_DIR/launchd/$PLIST_NAME"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LABEL="com.brew-deploy-agent.update"

UNINSTALL=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall) UNINSTALL=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--uninstall]"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_ok()  { log "OK    $1"; }
log_err() { log "ERROR $1"; }

unload_agent() {
    if launchctl list "$LABEL" &>/dev/null; then
        log "Unloading existing agent..."
        launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || \
            launchctl unload "$PLIST_DST" 2>/dev/null || true
        log_ok "Agent unloaded."
    fi
}

# ---------------------------------------------------------------------------
# Uninstall path
# ---------------------------------------------------------------------------

if $UNINSTALL; then
    log "Uninstalling $LABEL ..."
    unload_agent

    if [[ -f "$PLIST_DST" ]]; then
        rm -f "$PLIST_DST"
        log_ok "Removed $PLIST_DST"
    else
        log "Plist not found at $PLIST_DST — nothing to remove."
    fi

    log_ok "Uninstall complete."
    exit 0
fi

# ---------------------------------------------------------------------------
# Install path
# ---------------------------------------------------------------------------

if [[ ! -f "$PLIST_SRC" ]]; then
    log_err "Source plist not found: $PLIST_SRC"
    exit 1
fi

# Ensure target directory exists
mkdir -p "$HOME/Library/LaunchAgents"

# Unload existing agent if present
unload_agent

# Determine the absolute path to the update script
UPDATE_SCRIPT="$SCRIPT_DIR/update-brew.sh"

if [[ ! -x "$UPDATE_SCRIPT" ]]; then
    log "Making update-brew.sh executable..."
    chmod +x "$UPDATE_SCRIPT"
fi

# Generate the plist with the correct absolute path substituted in
log "Installing plist to $PLIST_DST ..."
LOG_DIR="$HOME/Library/Logs/brew-deploy-agent"
mkdir -p "$LOG_DIR"
sed -e "s|__UPDATE_SCRIPT_PATH__|$UPDATE_SCRIPT|g" \
    -e "s|__LOG_DIR__|$LOG_DIR|g" \
    "$PLIST_SRC" > "$PLIST_DST"
log_ok "Plist installed."

# Load the agent
log "Loading agent..."
if launchctl bootstrap "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || \
   launchctl load "$PLIST_DST" 2>/dev/null; then
    log_ok "Agent loaded: $LABEL"
else
    log_err "Failed to load agent. Check: launchctl list | grep brew-deploy"
    exit 1
fi

# Verify
if launchctl list "$LABEL" &>/dev/null; then
    log_ok "Agent is running."
else
    log "Agent registered but may not appear until its next scheduled run."
fi

log "Done. The update script will run daily at 11:00 AM."
log "Logs: ~/Library/Logs/brew-deploy-agent/"
