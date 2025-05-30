#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Installing packages requires root
if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[05-appimage-setup] Warning: Not running as root, but continuing in dry-run mode."
    else 
        echo "[05-appimage-setup] Error: This script must be run as root."
        exit 1
    fi
fi

run_cmd() {
    echo "[05-appimage-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

# Install FUSE (needed for AppImage execution)
# (Most AppImages require FUSE2; Arch's base includes fuse3 by default, so we ensure fuse2 is present)
run_cmd pacman -S --needed --noconfirm fuse2

echo "[05-appimage-setup] Installed FUSE support for AppImages."
echo "[05-appimage-setup] Note: To run an AppImage, download it, 'chmod +x' to make it executable, and launch it. For menu integration, consider tools like AppImageLauncher from AUR."
