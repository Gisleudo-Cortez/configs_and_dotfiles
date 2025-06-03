#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script is intended to run as a normal user.
# Paru will use sudo internally when needed.
if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[02b-aur-packages] Error: This script should be run as a regular user, not as root."
    echo "[02b-aur-packages] run-all.sh should delegate this script to run as the non-root user."
    exit 1
fi

run_cmd_user_eval() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        eval "$*"
    fi
}

echo "[02b-aur-packages] Preparing to install AUR packages using paru..."

# Define the list of AUR packages to install here using paru.
# Add more packages to this array as needed.
PACKAGES_TO_INSTALL_VIA_PARU=(
    "find-the-command" 
    "anydesk-bin"
    "neofetch-git"
    "grimblast-git"
    "waybar-module-pacman-updates-git"
    "wlr-randr-git"
    "zsh-theme-powerlevel10k-git"
    "zen-browser-bin"
    "satty"
    "hyprsunset"
)

OVERALL_SUCCESS=true

if ! command -v paru &> /dev/null; then
    echo "[02b-aur-packages] Error: 'paru' AUR helper is not installed or not found in PATH."
    echo "[02b-aur-packages] 'paru' is required to install the following AUR packages: ${PACKAGES_TO_INSTALL_VIA_PARU[*]}"
    echo "[02b-aur-packages] Please ensure 'paru' is installed (e.g., via script 02-official-packages.sh from chaotic-aur)."
    echo "[02b-aur-packages] Skipping installation of these AUR packages."
    # If paru is essential for these packages, we mark overall success as false.
    if [[ "${#PACKAGES_TO_INSTALL_VIA_PARU[@]}" -gt 0 ]]; then
        OVERALL_SUCCESS=false
    fi
else
    echo "[02b-aur-packages] Found 'paru'. Processing packages: ${PACKAGES_TO_INSTALL_VIA_PARU[*]}"
    for PACKAGE_NAME in "${PACKAGES_TO_INSTALL_VIA_PARU[@]}"; do
        echo ""
        echo "[02b-aur-packages] --- Processing AUR package with paru: $PACKAGE_NAME ---"
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ paru -S --noconfirm --needed $PACKAGE_NAME"
            echo "[02b-aur-packages] '$PACKAGE_NAME' assumed successful for dry run."
        elif paru -S --noconfirm --needed "$PACKAGE_NAME"; then
            echo "[02b-aur-packages] '$PACKAGE_NAME' installed successfully using paru."
        else
            echo "[02b-aur-packages] FAILED to install '$PACKAGE_NAME' using paru."
            OVERALL_SUCCESS=false # Mark overall script as having at least one failure
        fi
    done
fi

echo ""
if [[ "$OVERALL_SUCCESS" == true ]]; then
    echo "[02b-aur-packages] All specified AUR packages processed successfully (or skipped if paru was missing but no packages were listed)."
else
    echo "[02b-aur-packages] One or more AUR packages FAILED to install or were SKIPPED due to missing paru."
    # We only exit with 1 if there were packages to install and an issue occurred.
    # If PACKAGES_TO_INSTALL_VIA_PARU was empty, OVERALL_SUCCESS would remain true.
    if [[ "${#PACKAGES_TO_INSTALL_VIA_PARU[@]}" -gt 0 ]]; then
        exit 1 # Indicate failure to run-all.sh
    fi
fi

echo "[02b-aur-packages] AUR package processing complete."
