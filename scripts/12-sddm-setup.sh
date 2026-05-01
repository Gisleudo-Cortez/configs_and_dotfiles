#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

THEME_NAME="pixie"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF_FILE="$SDDM_CONF_DIR/10-theme.conf"

main() {
    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local dotfiles_root
    dotfiles_root=$(git -C "$script_dir" rev-parse --show-toplevel)

    local submodule_dir="$dotfiles_root/pixie-sddm"

    if [[ ! -d "$submodule_dir" ]]; then
        echo "[12-sddm-setup] Error: pixie-sddm submodule not found at $submodule_dir"
        echo "[12-sddm-setup] Run: git submodule update --init pixie-sddm"
        exit 1
    fi

    # Ensure submodule files are present (not an empty init)
    if [[ ! -f "$submodule_dir/Main.qml" ]]; then
        echo "[12-sddm-setup] Error: pixie-sddm submodule appears empty. Run: git submodule update --init pixie-sddm"
        exit 1
    fi

    echo "[12-sddm-setup] Installing Pixie SDDM theme from $submodule_dir"

    # Remove existing non-symlink theme dir
    if [[ -d "$THEME_DIR" && ! -L "$THEME_DIR" ]]; then
        echo "[12-sddm-setup] Removing old theme directory: $THEME_DIR"
        run_cmd rm -rf "$THEME_DIR"
    fi

    run_cmd mkdir -p "$THEME_DIR"
    run_cmd cp -r \
        "$submodule_dir/assets" \
        "$submodule_dir/components" \
        "$submodule_dir/Main.qml" \
        "$submodule_dir/metadata.desktop" \
        "$submodule_dir/theme.conf" \
        "$submodule_dir/LICENSE" \
        "$THEME_DIR/"
    run_cmd chmod -R 755 "$THEME_DIR"

    run_cmd mkdir -p "$SDDM_CONF_DIR"
    run_cmd bash -c "printf '[Theme]\nCurrent=$THEME_NAME\n' > '$SDDM_CONF_FILE'"

    run_cmd systemctl enable sddm.service

    echo "[12-sddm-setup] SDDM setup complete. Theme '$THEME_NAME' is active; will start on next reboot."
}

main
