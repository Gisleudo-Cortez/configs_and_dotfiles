#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Install Flatpak support
run_cmd pacman -S --needed --noconfirm flatpak

# Add Flathub repository for Flatpak (system-wide)
run_cmd flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "[04-flatpak-setup] Flatpak installed and Flathub repository added."
