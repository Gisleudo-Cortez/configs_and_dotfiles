#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

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
