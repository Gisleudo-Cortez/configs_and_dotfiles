#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -eq 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[09-python-tools] Note: Running in dry-run as root, but this script should be run as a normal user."
    else 
        echo "[09-python-tools] Skipping: This script should be run as a regular user (not as root)."
        exit 0 
    fi
fi

run_cmd_user() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        "$@"
    fi
}

echo "[09-python-tools] Installing 'uv' Python tool manager..."
if [[ "$DRY_RUN" == true ]]; then
    echo "[09-python-tools] DRY-RUN: Would download and run uv installer script from astral.sh."
else
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        echo "[09-python-tools] 'uv' installed successfully."
    else
        echo "[09-python-tools] ERROR: Failed to install 'uv'." >&2
        exit 1
    fi
fi

USER_LOCAL_BIN="$HOME/.local/bin"
PROFILE_FILE="$HOME/.profile"
# Ensure the PATH export line is robust for various shells if .profile is sourced by them
PATH_EXPORT_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\"" # Keep original for grep
ADD_TO_PROFILE_TEXT="
# Add user's local bin to PATH if it exists and is not already in PATH
if [ -d \"\$HOME/.local/bin\" ] && [[ \":\$PATH:\" != *\":\$HOME/.local/bin:\"* ]]; then
    export PATH=\"\$HOME/.local/bin:\$PATH\"
fi"


if [[ ! ":$PATH:" == *":$USER_LOCAL_BIN:"* ]]; then
    export PATH="$USER_LOCAL_BIN:$PATH"
    echo "[09-python-tools] Added $USER_LOCAL_BIN to PATH for current session."
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "[09-python-tools] DRY-RUN: Would check and potentially add $USER_LOCAL_BIN to $PROFILE_FILE."
else
    if [[ -f "$PROFILE_FILE" ]]; then
        if ! grep -qF "$PATH_EXPORT_LINE" "$PROFILE_FILE" && ! grep -qF "\$HOME/.local/bin:\$PATH" "$PROFILE_FILE"; then # Check more broadly
            echo "[09-python-tools] Adding $USER_LOCAL_BIN to PATH in $PROFILE_FILE."
            echo "$ADD_TO_PROFILE_TEXT" >> "$PROFILE_FILE"
        else
            echo "[09-python-tools] $USER_LOCAL_BIN PATH export already appears in $PROFILE_FILE."
        fi
    else
        echo "[09-python-tools] $PROFILE_FILE does not exist. Creating and adding PATH."
        echo "$ADD_TO_PROFILE_TEXT" > "$PROFILE_FILE"
    fi
    echo "[09-python-tools] Please source $PROFILE_FILE or re-login for permanent PATH changes to take effect."
fi

if command -v uv &> /dev/null; then
    echo "[09-python-tools] Installing 'ruff' linter using uv..."
    run_cmd_user uv tool install ruff
    echo "[09-python-tools] 'ruff' linter setup via uv complete."
else
    echo "[09-python-tools] 'uv' command not found after installation attempt. Skipping ruff install." >&2
    if [[ "$DRY_RUN" == false ]]; then
      exit 1
    fi
fi

echo "[09-python-tools] Python tools setup script finished."
