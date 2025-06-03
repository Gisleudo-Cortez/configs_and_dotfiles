#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[02b-aur-packages] Error: This script should be run as a regular user, not as root." >&2
    echo "[02b-aur-packages] run-all.sh should delegate this script to run as the non-root user." >&2
    exit 1
fi

# Simplified command runner for user context
run_cmd_user() {
    echo "EXECUTING (user: $(whoami)) ➜ $*"
    "$@"
}

echo "[02b-aur-packages] Preparing to install AUR packages using paru..."

PACKAGES_TO_INSTALL_VIA_PARU=(
    "find-the-command" 
    "anydesk-bin"
    "neofetch-git"
    "grimblast-git"
    "waybar-module-pacman-updates-git"
    "wlr-randr-git"
    "zsh-theme-powerlevel10k-git"
    "zen-browser-bin"
    "clipman"
)

OVERALL_SUCCESS=true

if ! command -v paru &> /dev/null; then
    echo "[02b-aur-packages] Error: 'paru' AUR helper is not installed or not found in PATH." >&2
    echo "[02b-aur-packages] 'paru' is required to install the following AUR packages: ${PACKAGES_TO_INSTALL_VIA_PARU[*]}" >&2
    echo "[02b-aur-packages] Please ensure 'paru' is installed (e.g., via script 02-official-packages.sh from chaotic-aur)." >&2
    echo "[02b-aur-packages] Skipping installation of these AUR packages." >&2
    if [[ "${#PACKAGES_TO_INSTALL_VIA_PARU[@]}" -gt 0 ]]; then
        OVERALL_SUCCESS=false
    fi
else
    echo "[02b-aur-packages] Found 'paru'. Processing packages: ${PACKAGES_TO_INSTALL_VIA_PARU[*]}"
    for PACKAGE_NAME in "${PACKAGES_TO_INSTALL_VIA_PARU[@]}"; do
        echo ""
        echo "[02b-aur-packages] --- Processing AUR package with paru: $PACKAGE_NAME ---"
        
        COMMAND_TO_RUN=(paru -S --noconfirm --needed "$PACKAGE_NAME")

        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ ${COMMAND_TO_RUN[*]}"
            echo "[02b-aur-packages] '$PACKAGE_NAME' assumed successful for dry run."
        elif run_cmd_user "${COMMAND_TO_RUN[@]}"; then
            echo "[02b-aur-packages] '$PACKAGE_NAME' installed successfully using paru."
        else
            echo "[02b-aur-packages] FAILED to install '$PACKAGE_NAME' using paru." >&2
            OVERALL_SUCCESS=false
        fi
    done
fi

echo ""
if [[ "$OVERALL_SUCCESS" == true ]]; then
    echo "[02b-aur-packages] All specified AUR packages processed successfully (or skipped if paru was missing but no packages were listed)."
else
    echo "[02b-aur-packages] One or more AUR packages FAILED to install or were SKIPPED due to missing paru." >&2
    if [[ "${#PACKAGES_TO_INSTALL_VIA_PARU[@]}" -gt 0 && "$DRY_RUN" == false ]]; then # Only exit with error if not a dry run
        exit 1
    fi
fi

echo "[02b-aur-packages] AUR package processing complete."
