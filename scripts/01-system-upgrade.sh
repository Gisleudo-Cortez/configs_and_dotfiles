#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Update package databases and perform a full system upgrade
echo "[01-system-upgrade] Performing full system upgrade (pacman -Syu --noconfirm)..."
run_cmd pacman -Syu --noconfirm

echo "[01-system-upgrade] System upgrade process complete."
