#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Install CUPS (Common Unix Printing System) and related tools
PKGS=(cups cups-pdf system-config-printer)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

# Enable and start the CUPS service
run_cmd systemctl enable --now cups.service

echo "[06-printer-setup] CUPS installed and service enabled."
echo "[06-printer-setup] You can configure printers via the 'system-config-printer' GUI or CUPS web interface (http://localhost:631)."
