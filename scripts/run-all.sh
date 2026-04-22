#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN_FLAG=""

# Check for --dry-run argument
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN_FLAG="--dry-run"
    echo "[run-all] --- DRY RUN MODE ACTIVATED ---"
fi

# We source helpers to set up the environment, but we won't use run_cmd
# to invoke the scripts themselves, as we want the scripts to handle the dry-run flag.
source "$SCRIPT_DIR/helpers.sh"

ROOT_SCRIPTS=(
    "00-enable-repos.sh"
    "01-system-upgrade.sh"
    "02-official-packages.sh"
    
    
)

USER_SCRIPTS=(
    "02b-aur-packages.sh"
    "09-python-tools.sh"
    
    "11-deploy-dotfiles.sh"
)

# --- Main Logic ---

main() {
    need_root

    # 1. Run Root Scripts
    for script in "${ROOT_SCRIPTS[@]}"; do
        echo -e "\n[run-all] === Running $script (as root) ==="
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            # FIX: Execute directly so the script receives the --dry-run flag
            # and performs its own logging/checking.
            "$SCRIPT_DIR/$script" $DRY_RUN_FLAG
        else
            echo "[run-all] Error: Script '$script' not found or not executable."
            exit 1
        fi
        echo "[run-all] === Completed $script ==="
    done

    # Determine Non-Root User
    local target_user="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
    
    if [[ -z "$target_user" || "$target_user" == "root" ]]; then
        echo "[run-all] Critical: Cannot determine a non-root user to run user-specific scripts."
        exit 1
    fi

    # 2. Run User Scripts
    for script in "${USER_SCRIPTS[@]}"; do
        echo -e "\n[run-all] === Running $script (as user: $target_user) ==="
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            if [[ "${DRY_RUN:-false}" == true ]]; then
                # In dry run, we still execute the script with the flag
                # but we log exactly how we call it.
                echo "DRY-RUN (Orchestrator) ➜ sudo -u $target_user $SCRIPT_DIR/$script $DRY_RUN_FLAG"
                sudo -u "$target_user" "$SCRIPT_DIR/$script" $DRY_RUN_FLAG
            else
                sudo -u "$target_user" "$SCRIPT_DIR/$script" $DRY_RUN_FLAG
            fi
        else
            echo "[run-all] Error: Script '$script' not found or not executable."
            exit 1
        fi
        echo "[run-all] === Completed $script ==="
    done

    echo -e "\n[run-all] All applicable scripts executed."
}

main "$@"
