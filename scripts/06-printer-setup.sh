#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# --- CUPS and core printing stack ---
PKGS=(cups cups-pdf cups-filters ghostscript gsfonts system-config-printer avahi nss-mdns)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

run_cmd systemctl enable --now cups.service
run_cmd systemctl enable --now avahi-daemon.service
echo "[06-printer-setup] Avahi daemon enabled for network printer discovery."

echo "[06-printer-setup] CUPS installed and service enabled."

# --- Epson L3210 EcoTank driver (AUR) ---
EPSON_AUR_PKG="epson-inkjet-printer-202101w"
EPSON_FILTER_SRC="/opt/epson-inkjet-printer-202101w/cups/lib/filter/epson_inkjet_printer_filter"
EPSON_FILTER_DEST="/usr/lib/cups/filter/epson_inkjet_printer_filter"

if ! command -v paru &>/dev/null; then
    echo "[06-printer-setup] Warning: 'paru' AUR helper not found. Skipping Epson L3210 driver."
    echo "[06-printer-setup] Install manually: paru -S ${EPSON_AUR_PKG}"
else
    run_cmd_user paru -S --needed --noconfirm "${EPSON_AUR_PKG}"

    # The AUR .install script should create this symlink, but verify it exists
    if [[ -f "${EPSON_FILTER_SRC}" && ! -f "${EPSON_FILTER_DEST}" ]]; then
        run_cmd ln -s "${EPSON_FILTER_SRC}" "${EPSON_FILTER_DEST}"
        echo "[06-printer-setup] Created CUPS filter symlink for Epson L3210."
    fi

    echo "[06-printer-setup] Epson L3210 driver installed."
fi

echo "[06-printer-setup] Printer setup complete."
echo "[06-printer-setup] Add your printer via 'system-config-printer' GUI or http://localhost:631"
echo "[06-printer-setup] Scanner: install 'epsonscan2' (AUR) for scanning support"
echo "[06-printer-setup] Ink levels: install 'epson-printer-utility' (AUR)"
