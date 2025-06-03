#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[05-appimage-setup] Warning: Not running as root, but continuing in dry-run mode." >&2
    else 
        echo "[05-appimage-setup] Error: This script must be run as root." >&2
        exit 1
    fi
fi

run_cmd() {
    echo "[05-appimage-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

run_cmd pacman -S --needed --noconfirm fuse2

echo "[05-appimage-setup] Installed FUSE support for AppImages."
echo "[05-appimage-setup] Note: To run an AppImage, download it, 'chmod +x' to make it executable, and launch it. For menu integration, consider tools like AppImageLauncher from AUR."
