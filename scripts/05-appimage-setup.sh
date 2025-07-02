#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Install FUSE (needed for AppImage execution)
# (Most AppImages require FUSE2; Arch's base includes fuse3 by default, so we ensure fuse2 is present)
run_cmd pacman -S --needed --noconfirm fuse2

echo "[05-appimage-setup] Installed FUSE support for AppImages."
echo "[05-appimage-setup] Note: To run an AppImage, download it, 'chmod +x' to make it executable, and launch it. For menu integration, consider tools like AppImageLauncher from AUR."
