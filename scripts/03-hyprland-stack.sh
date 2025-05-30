#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Needs root to install packages
if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[03-hyprland-stack] Warning: Not running as root, but continuing in dry-run mode."
    else 
        echo "[03-hyprland-stack] Error: This script must be run as root."
        exit 1
    fi
fi

run_cmd() {
    echo "[03-hyprland-stack] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

# Packages for Hyprland and related components
PKGS=(
    hyprland         # Hyprland compositor
    waybar           # Status bar for Wayland
    hyprpaper        # Wallpaper utility for Hyprland
    hyprlock         # Lock screen for Hyprland
    polkit           # Polkit for privilege escalation (required for Hyprland)
    xdg-desktop-portal
    xdg-desktop-portal-hyprland  # Hyprland support for xdg portals (screensharing, etc.)
)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

echo "[03-hyprland-stack] Hyprland and related packages installed. Make sure to configure Hyprland before use (see dotfiles or examples)."
