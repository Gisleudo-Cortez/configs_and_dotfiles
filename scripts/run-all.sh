#!/usr/bin/env bash
set -euo pipefail

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN_FLAG=""

# Check for --dry-run argument
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN_FLAG="--dry-run"
    echo "[run-all] --- DRY RUN MODE ACTIVATED ---"
fi

# Source the helper functions
source "$SCRIPT_DIR/helpers.sh"

# Scripts that must run as root
ROOT_SCRIPTS=(
    "00-enable-repos.sh"
    "01-system-upgrade.sh"
    "02-official-packages.sh"
    "03-hyprland-stack.sh"
    "04-flatpak-setup.sh"
    "05-appimage-setup.sh"
    "06-printer-setup.sh"
    "07-virt-setup.sh"
    "08-gaming-setup.sh"
)

# Scripts that must run as the normal user
USER_SCRIPTS=(
    "02b-aur-packages.sh"
    "09-python-tools.sh"
    "10-git-setup.sh"
    "11-deploy-dotfiles.sh"
)

# --- Main Logic ---

main() {
    need_root

    for script in "${ROOT_SCRIPTS[@]}"; do
        echo -e "\n[run-all] === Running $script (as root) ==="
        run_cmd "$SCRIPT_DIR/$script" $DRY_RUN_FLAG
        echo "[run-all] === Completed $script ==="
    done

    local target_user="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
    if [[ -z "$target_user" || "$target_user" == "root" ]]; then
        echo "[run-all] Critical: Cannot determine a non-root user to run user-specific scripts."
        exit 1
    fi

    for script in "${USER_SCRIPTS[@]}"; do
        echo -e "\n[run-all] === Running $script (as user: $target_user) ==="
        run_cmd_user "$SCRIPT_DIR/$script" $DRY_RUN_FLAG
        echo "[run-all] === Completed $script ==="
    done

    echo -e "\n[run-all] All applicable scripts executed."
}

main "$@"
