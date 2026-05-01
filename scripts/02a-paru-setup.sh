#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

main() {
    if command -v paru &>/dev/null; then
        echo "[02a-paru-setup] paru already installed. Skipping."
        return 0
    fi

    local target_user="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
    if [[ -z "$target_user" || "$target_user" == "root" ]]; then
        echo "[02a-paru-setup] Error: Cannot determine a non-root user to build paru."
        exit 1
    fi

    echo "[02a-paru-setup] Installing build dependencies..."
    run_cmd pacman -S --needed --noconfirm base-devel git

    local build_dir
    build_dir=$(mktemp -d)
    run_cmd chown "$target_user:$target_user" "$build_dir"

    echo "[02a-paru-setup] Cloning paru-bin AUR package..."
    run_cmd_user git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"

    echo "[02a-paru-setup] Building and installing paru-bin as $target_user..."
    run_cmd_user bash -c "cd '$build_dir/paru-bin' && makepkg -si --noconfirm"

    run_cmd rm -rf "$build_dir"

    if [[ "$DRY_RUN" == false ]]; then
        if ! command -v paru &>/dev/null; then
            echo "[02a-paru-setup] Error: paru installation failed."
            exit 1
        fi
        echo "[02a-paru-setup] paru installed successfully: $(paru --version | head -1)"
    fi
}

main
