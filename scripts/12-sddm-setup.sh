#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

THEME_NAME="synth-glass"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
SDDM_CONF_DIR="/etc/sddm.conf.d"

main() {
    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local dotfiles_root
    dotfiles_root=$(git -C "$script_dir" rev-parse --show-toplevel)

    echo "[12-sddm-setup] Deploying SDDM theme '$THEME_NAME' from $dotfiles_root"

    # Remove manually installed theme files so stow can create symlinks
    if [[ -d "$THEME_DIR" && ! -L "$THEME_DIR" ]]; then
        echo "[12-sddm-setup] Removing manually installed theme dir: $THEME_DIR"
        run_cmd rm -rf "$THEME_DIR"
    fi

    # Ensure /etc/sddm.conf.d exists
    if [[ ! -d "$SDDM_CONF_DIR" ]]; then
        echo "[12-sddm-setup] Creating $SDDM_CONF_DIR"
        run_cmd mkdir -p "$SDDM_CONF_DIR"
    fi

    cd "$dotfiles_root"

    echo "[12-sddm-setup] Stowing sddm package to /"
    run_cmd stow -Svt / sddm

    echo "[12-sddm-setup] SDDM setup complete. Theme '$THEME_NAME' is active."
}

main
