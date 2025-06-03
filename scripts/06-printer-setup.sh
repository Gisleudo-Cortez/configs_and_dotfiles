#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[06-printer-setup] Warning: Not running as root, but continuing in dry-run mode." >&2
    else 
        echo "[06-printer-setup] Error: This script must be run as root." >&2
        exit 1
    fi
fi

run_cmd() {
    echo "[06-printer-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

PKGS=(cups cups-pdf system-config-printer)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"
run_cmd systemctl enable --now cups.service

echo "[06-printer-setup] CUPS installed and service enabled."
echo "[06-printer-setup] You can configure printers via the 'system-config-printer' GUI or CUPS web interface (http://localhost:631)."
