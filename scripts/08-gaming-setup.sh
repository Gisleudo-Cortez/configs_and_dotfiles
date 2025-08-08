#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# --- GPU Driver Detection ---

detect_gpu_vendor() {
    if lspci | grep -E "VGA|3D" | grep -iq "NVIDIA"; then
        echo "NVIDIA"
    elif lspci | grep -E "VGA|3D" | grep -iq "AMD"; then
        echo "AMD"
    elif lspci | grep -E "VGA|3D" | grep -iq "Intel"; then
        echo "INTEL"
    else
        echo "UNKNOWN"
    fi
}

# --- Main Logic ---

main() {
    local vendor
    vendor=$(detect_gpu_vendor)
    
    local pkgs_to_install=()
    pkgs_to_install+=("steam") # Steam is always needed

    echo "[08-gaming-setup] Detected GPU Vendor: $vendor"

    case "$vendor" in
        "NVIDIA")
            echo "[08-gaming-setup] Selecting NVIDIA drivers..."
            pkgs_to_install+=(
                "nvidia-utils" "nvidia-settings" "lib32-nvidia-utils"
                "vulkan-icd-loader" "lib32-vulkan-icd-loader"
            )
            ;;
        "AMD")
            echo "[08-gaming-setup] Selecting AMD drivers..."
            pkgs_to_install+=(
                "mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon"
                "vulkan-icd-loader" "lib32-vulkan-icd-loader"
            )
            ;;
        "INTEL")
            echo "[08-gaming-setup] Selecting Intel drivers..."
            pkgs_to_install+=(
                "mesa" "lib32-mesa" "vulkan-intel" "lib32-vulkan-intel"
                "vulkan-icd-loader" "lib32-vulkan-icd-loader"
            )
            ;;
        *)
            echo "[08-gaming-setup] WARNING: Could not determine GPU vendor."
            echo "[08-gaming-setup] Installing generic Vulkan packages only."
            pkgs_to_install+=("vulkan-icd-loader" "lib32-vulkan-icd-loader")
            ;;
    esac

    echo "[08-gaming-setup] Installing selected packages: ${pkgs_to_install[*]}"
    run_cmd pacman -S --needed --noconfirm "${pkgs_to_install[@]}"

    echo "[08-gaming-setup] Gaming setup script finished."
    echo "[08-gaming-setup] Note: Ensure the 'multilib' repository is enabled for 32-bit libraries needed by Steam."
}

main
