#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_user

# Ensure the user owns their own .local directory
echo "[09-python-tools] Ensuring correct ownership of ~/.local..."
if [[ -d "$HOME/.local" ]]; then
    run_cmd sudo chown -R "$(whoami):$(whoami)" "$HOME/.local"
fi

# Install 'uv' (Unified Python environment tool)
echo "[09-python-tools] Installing 'uv' Python tool manager..."
if ! bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh"; then
    echo "[09-python-tools] ERROR: Failed to install 'uv'."
    exit 1
fi
echo "[09-python-tools] 'uv' installed successfully."

# Add ~/.local/bin to PATH for the current session
USER_LOCAL_BIN="$HOME/.local/bin"
if [[ ! ":$PATH:" == *":$USER_LOCAL_BIN:"* ]]; then
    export PATH="$USER_LOCAL_BIN:$PATH"
    echo "[09-python-tools] Added $USER_LOCAL_BIN to PATH for current session."
fi

# Inform the user to add ~/.local/bin to their PATH permanently
echo "[09-python-tools] To make 'uv' and other tools installed in $USER_LOCAL_BIN available in all future sessions,"
echo "[09-python-tools] please add the following line to your shell's startup file (e.g., ~/.bashrc, ~/.zshrc, or ~/.profile):"
echo -e "\n    export PATH=\"\$HOME/.local/bin:\$PATH\"\n"

# Install 'ruff' linter using uv
if command -v uv &>/dev/null; then
    echo "[09-python-tools] Installing 'ruff' linter using uv..."
    run_cmd uv tool install ruff
    echo "[09-python-tools] 'ruff' linter setup via uv complete."
else
    echo "[09-python-tools] 'uv' command not found after installation attempt. Skipping ruff install."
    if [[ "$DRY_RUN" == false ]]; then
      exit 1
    fi
fi

echo "[09-python-tools] Python tools setup script finished."
