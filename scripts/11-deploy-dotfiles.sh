#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_user

# --- Configuration ---
# The script now assumes it is located in a subdirectory of the dotfiles git repository.
# It will automatically find the git repo root.
STOW_PACKAGES_TO_DEPLOY=(
    "zshrc"
    "fish"
    "hypr"
    "kitty"
    "nvim"
    "waybar"
    "rofi"
)

# --- Main Logic ---

main() {
    if ! command -v stow &>/dev/null; then
        echo "[11-deploy-dotfiles] Error: 'stow' command not found. Please install it first."
        exit 1
    fi

    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local dotfiles_root
    dotfiles_root=$(git -C "$script_dir" rev-parse --show-toplevel)

    if [[ -z "$dotfiles_root" ]]; then
        echo "[11-deploy-dotfiles] Error: Could not find the git repository root."
        exit 1
    fi

    echo "[11-deploy-dotfiles] Deploying dotfiles from $dotfiles_root for user $(whoami)"

    cd "$dotfiles_root"

    for pkg in "${STOW_PACKAGES_TO_DEPLOY[@]}"; do
        if [[ -d "$pkg" ]]; then
            echo "[11-deploy-dotfiles] Stowing package: $pkg"
            run_cmd_user stow -Rvt "$HOME" "$pkg"
        else
            echo "[11-deploy-dotfiles] Warning: Stow package directory '$pkg' not found. Skipping."
        fi
    done

    echo "[11-deploy-dotfiles] Dotfiles deployment complete."
}

main
