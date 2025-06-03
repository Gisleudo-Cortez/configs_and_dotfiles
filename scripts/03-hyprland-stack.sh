#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[03-hyprland-stack] Warning: Not running as root, but continuing in dry-run mode." >&2
    else 
        echo "[03-hyprland-stack] Error: This script must be run as root." >&2
        exit 1
    fi
fi

run_cmd() {
    echo "[03-hyprland-stack] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

PKGS=(
    hyprland
    waybar
    hyprpaper
    hyprlock
    polkit # polkit-gnome or similar might be needed for an agent if not covered
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

echo "[03-hyprland-stack] Hyprland and related packages installed. Make sure to configure Hyprland before use (see dotfiles or examples)."
