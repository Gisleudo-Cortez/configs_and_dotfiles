#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Installing packages requires root
if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[04-flatpak-setup] Warning: Not running as root, but continuing in dry-run mode."
    else 
        echo "[04-flatpak-setup] Error: This script must be run as root."
        exit 1
    fi
fi

run_cmd() {
    echo "[04-flatpak-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

# Install Flatpak support
run_cmd pacman -S --needed --noconfirm flatpak

# Add Flathub repository for Flatpak (system-wide)
run_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "[04-flatpak-setup] Flatpak installed and Flathub repository added."
