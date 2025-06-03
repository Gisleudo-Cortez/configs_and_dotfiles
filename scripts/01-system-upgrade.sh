#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[01-system-upgrade] Warning: Not running as root, but continuing in dry-run mode." >&2
    else
        echo "[01-system-upgrade] Error: This script must be run as root." >&2
        exit 1
    fi
fi

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

echo "[01-system-upgrade] Performing full system upgrade (pacman -Syu --noconfirm)..."
run_cmd pacman -Syu --noconfirm

echo "[01-system-upgrade] System upgrade process complete."
