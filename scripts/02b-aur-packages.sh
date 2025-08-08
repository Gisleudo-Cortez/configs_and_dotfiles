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

# Reads a list of AUR packages from the 'packages-aur.txt' file.
# The file should contain one package name per line.
# Lines starting with '#' and empty lines are ignored.
get_aur_packages_from_file() {
    local package_file
    package_file="$(dirname "$0")/packages-aur.txt"
    if [[ ! -f "$package_file" ]]; then
        echo "[02b-aur-packages] Error: Package file not found at '$package_file'"
        return 1
    fi
    # Read file, filter out comments and empty lines
    grep -v -E '^\s*#|^\s*
 "$package_file"
}

# --- Main Logic ---

main() {
    if ! command -v paru &>/dev/null; then
        echo "[02b-aur-packages] Error: 'paru' AUR helper is not installed."
        exit 1
    fi

    # Read packages from the file into an array
    local aur_packages
    mapfile -t aur_packages < <(get_aur_packages_from_file)
    if [[ $? -ne 0 || ${#aur_packages[@]} -eq 0 ]]; then
        echo "[02b-aur-packages] Could not read packages from file or package file is empty. Exiting."
        return 1
    fi

    echo "[02b-aur-packages] Installing AUR packages: ${aur_packages[*]}"
    if ! paru -S --needed --noconfirm "${aur_packages[@]}"; then
        echo "[02b-aur-packages] One or more AUR packages failed to install."
        exit 1
    fi

    echo "[02b-aur-packages] AUR package installation complete."
}

main
