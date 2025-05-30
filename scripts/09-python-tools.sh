#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script is intended to run as a normal user (installs tools in user's home)
if [[ "$EUID" -eq 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[09-python-tools] Note: Running in dry-run as root, but this script should be run as a normal user."
    else 
        echo "[09-python-tools] Skipping: This script should be run as a regular user (not as root)."
        exit 0
    fi
fi

run_cmd() {
    echo "[09-python-tools] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

# Install 'uv' (Unified Python environment tool) via official installer script
if [[ "$DRY_RUN" == true ]]; then
    echo "[09-python-tools] Would download and run uv installer script from astral.sh (skipped in dry-run)."
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Ensure uv is in PATH (the installer typically places it in ~/.local/bin)
if [[ -z "$(command -v uv || true)" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install the 'ruff' Python linter using uv
run_cmd uv tool install ruff

echo "[09-python-tools] 'uv' installed and 'ruff' linter set up via uv."
