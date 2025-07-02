#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Install Steam and NVIDIA proprietary drivers (including 32-bit libs for Steam) and Vulkan support
PKGS=(
    steam
    nvidia nvidia-utils nvidia-settings
    lib32-nvidia-utils 
    vulkan-icd-loader lib32-vulkan-icd-loader
)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

echo "[08-gaming-setup] Steam and NVIDIA drivers installed."
echo "[08-gaming-setup] Note: If using a non-NVIDIA GPU, adjust the script to install the appropriate drivers (e.g., 'mesa' for AMD/Intel, etc.). Ensure 'multilib' repository is enabled for 32-bit libraries needed by Steam."
