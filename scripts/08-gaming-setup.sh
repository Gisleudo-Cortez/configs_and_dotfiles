#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[08-gaming-setup] Warning: Not running as root, but continuing in dry-run mode." >&2
    else 
        echo "[08-gaming-setup] Error: This script must be run as root." >&2
        exit 1
    fi
fi

run_cmd() {
    echo "[08-gaming-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

PKGS=(
    steam
    nvidia nvidia-utils nvidia-settings
    lib32-nvidia-utils 
    vulkan-icd-loader lib32-vulkan-icd-loader
)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

echo "[08-gaming-setup] Steam and NVIDIA drivers installed."
echo "[08-gaming-setup] Note: If using a non-NVIDIA GPU, adjust the script to install the appropriate drivers (e.g., 'mesa' for AMD/Intel, etc.). Ensure 'multilib' repository is enabled for 32-bit libraries needed by Steam."
