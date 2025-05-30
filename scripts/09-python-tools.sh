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
        exit 0 # Exit 0 because this is not an error in the run-all sequence, just a skip condition.
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

# Install 'uv' (Unified Python environment tool) via official installer script
echo "[09-python-tools] Installing 'uv' Python tool manager..."
if [[ "$DRY_RUN" == true ]]; then
    echo "[09-python-tools] DRY-RUN: Would download and run uv installer script from astral.sh."
else
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        echo "[09-python-tools] 'uv' installed successfully."
    else
        echo "[09-python-tools] ERROR: Failed to install 'uv'."
        exit 1
    fi
fi

# Ensure uv is in PATH for this script's session if just installed
# and attempt to add ~/.local/bin to PATH in .profile for future sessions.
USER_LOCAL_BIN="$HOME/.local/bin"
PROFILE_FILE="$HOME/.profile"
PATH_EXPORT_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""

if [[ ! ":$PATH:" == *":$USER_LOCAL_BIN:"* ]]; then
    export PATH="$USER_LOCAL_BIN:$PATH"
    echo "[09-python-tools] Added $USER_LOCAL_BIN to PATH for current session."
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "[09-python-tools] DRY-RUN: Would check and potentially add $USER_LOCAL_BIN to $PROFILE_FILE."
else
    if [[ -f "$PROFILE_FILE" ]]; then
        if ! grep -qF "$PATH_EXPORT_LINE" "$PROFILE_FILE"; then
            echo "[09-python-tools] Adding $USER_LOCAL_BIN to PATH in $PROFILE_FILE."
            echo -e "\n# Add user's local bin to PATH if not already set by other means\nif [ -d \"\$HOME/.local/bin\" ] && [[ \":\$PATH:\" != *\":\$HOME/.local/bin:\"* ]]; then\n    $PATH_EXPORT_LINE\nfi" >> "$PROFILE_FILE"
        else
            echo "[09-python-tools] $USER_LOCAL_BIN PATH export already in $PROFILE_FILE."
        fi
    else
        echo "[09-python-tools] $PROFILE_FILE does not exist. Creating and adding PATH."
        echo -e "# Add user's local bin to PATH\nif [ -d \"\$HOME/.local/bin\" ] && [[ \":\$PATH:\" != *\":\$HOME/.local/bin:\"* ]]; then\n    $PATH_EXPORT_LINE\nfi" > "$PROFILE_FILE"
    fi
    echo "[09-python-tools] Please source $PROFILE_FILE or re-login for permanent PATH changes to take effect."
fi


# Install the 'ruff' Python linter using uv
if command -v uv &> /dev/null; then
    echo "[09-python-tools] Installing 'ruff' linter using uv..."
    run_cmd_user uv tool install ruff
    echo "[09-python-tools] 'ruff' linter setup via uv complete."
else
    echo "[09-python-tools] 'uv' command not found after installation attempt. Skipping ruff install."
    if [[ "$DRY_RUN" == false ]]; then
      exit 1 # Fail if uv wasn't installed properly
    fi
fi

echo "[09-python-tools] Python tools setup script finished."
