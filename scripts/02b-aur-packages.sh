#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_user

# --- Package List ---

get_aur_packages() {
    local pkgs=(
        "find-the-command"
        "anydesk-bin"
        "neofetch-git"
        "grimblast-git"
        "waybar-module-pacman-updates-git"
        "wine-stable"
        "wlr-randr-git"
        "zsh-theme-powerlevel10k-git"
        "zen-browser-bin"
        "satty"
        "hyprsunset"
        # Themes
        "gruvbox-material-gtk-theme-git"
        "catppuccin-gtk-theme-macchiato"
        "catppuccin-gtk-theme-latte"
        "catppuccin-gtk-theme-frappe"
        "material-gtk-theme-git"
        "gtk-cyberpunk-neon-theme-git"
    )
    echo "${pkgs[@]}"
}

# --- Main Logic ---

main() {
    if ! command -v paru &>/dev/null; then
        echo "[02b-aur-packages] Error: 'paru' AUR helper is not installed."
        exit 1
    fi

    local aur_packages
    aur_packages=$(get_aur_packages)

    if [[ -z "$aur_packages" ]]; then
        echo "[02b-aur-packages] No AUR packages to install."
        exit 0
    fi

    echo "[02b-aur-packages] Installing AUR packages: ${aur_packages}"
    if ! paru -S --needed --noconfirm $aur_packages; then
        echo "[02b-aur-packages] One or more AUR packages failed to install."
        exit 1
    fi

    echo "[02b-aur-packages] AUR package installation complete."
}

main
