#!/usr/bin/env bash
set -euo pipefail

# Support dry-run flag (simulate commands without executing)
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Ensure this script is run as root (required for pacman)
if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[01-system-upgrade] Warning: Not running as root, but continuing in dry-run mode."
    else
        echo "[01-system-upgrade] Error: This script must be run as root."
        exit 1
    fi
fi

# Helper to run commands (echoes the command when dry-run or before execution)
run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

# Update package databases and perform a full system upgrade
echo "[01-system-upgrade] Performing full system upgrade (pacman -Syu --noconfirm)..."
run_cmd pacman -Syu --noconfirm

echo "[01-system-upgrade] System upgrade process complete."
