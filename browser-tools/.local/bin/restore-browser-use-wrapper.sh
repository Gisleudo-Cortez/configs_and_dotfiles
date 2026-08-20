#!/bin/bash
# restore-browser-use-wrapper — re-apply the Chrome CDP ensure wrapper after uv tool upgrade
# Usage: bash ~/.local/bin/restore-browser-use-wrapper.sh
#
# The wrapper at ~/.local/share/uv/tools/browser-use/bin/browser-use gets
# overwritten by `uv tool upgrade browser-use`. This script restores it
# from the version-controlled source in the dotfiles repo.

set -e

BROWSER_USE_DIR="$HOME/.local/share/uv/tools/browser-use/bin"
WRAPPER_SRC="$HOME/Documents/configs_and_dotfiles/browser-tools/.local/share/uv/browser-use-wrapper"
REAL_BIN="$BROWSER_USE_DIR/browser-use-real"
WRAPPER="$BROWSER_USE_DIR/browser-use"

if [ ! -d "$BROWSER_USE_DIR" ]; then
    echo "ERROR: browser-use tool dir not found at $BROWSER_USE_DIR" >&2
    exit 1
fi

# Step 1: Save the current (upgraded) binary as browser-use-real
cp "$WRAPPER" "$REAL_BIN"
echo "Saved current binary to browser-use-real"

# Step 2: Copy the wrapper over browser-use
cp "$WRAPPER_SRC" "$WRAPPER"
chmod +x "$WRAPPER"
echo "Restored wrapper to $WRAPPER"

# Step 3: Verify
"$WRAPPER" --version 2>/dev/null && echo "Wrapper OK" || echo "WARNING: wrapper verification failed"