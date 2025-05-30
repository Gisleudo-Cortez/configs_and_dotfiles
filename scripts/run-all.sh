#!/usr/bin/env bash
set -euo pipefail

# Determine the directory of this script (scripts/ directory)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN_FLAG=""

# Check for --dry-run argument
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN_FLAG="--dry-run"
    echo "[run-all] --- DRY RUN MODE ACTIVATED ---"
fi

# Scripts that must run as root
ROOT_SCRIPTS=(
    "00-enable-repos.sh"
    "01-system-upgrade.sh"
    "02-official-packages.sh"
    "02b-aur-packages.sh"
    "03-hyprland-stack.sh"
    "04-flatpak-setup.sh"
    "05-appimage-setup.sh"
    "06-printer-setup.sh"
    "07-virt-setup.sh"
    "08-gaming-setup.sh"
)

# Scripts that must run as the normal user
USER_SCRIPTS=(
    "09-python-tools.sh"
    "10-git-setup.sh"
    "11-deploy-dotfiles.sh"
)

# Check if running as root for root scripts
if [[ "$EUID" -ne 0 ]]; then
    echo "[run-all] This script needs to be run with sudo or as root to execute system-wide changes."
    if [[ -z "$DRY_RUN_FLAG" ]]; then
        echo "[run-all] Aborting. Please run with sudo."
        exit 1
    else
        echo "[run-all] Continuing in dry-run mode without root privileges. Root commands will be simulated."
    fi
fi

# Execute root scripts
for script_name in "${ROOT_SCRIPTS[@]}"; do
    script_path="$SCRIPT_DIR/$script_name"
    if [[ -f "$script_path" ]]; then
        echo ""
        echo "[run-all] === Running $script_name (as root) ==="
        # Pass through --dry-run if it was set
        if [[ "$EUID" -ne 0 && -n "$DRY_RUN_FLAG" ]]; then # Simulating root execution in dry run
             echo "DRY-RUN (as root) ➜ $script_path $DRY_RUN_FLAG"
        else
            "$script_path" $DRY_RUN_FLAG
        fi
        echo "[run-all] === Completed $script_name ==="
    else
        echo "[run-all] Warning: Root script $script_name not found. Skipping."
    fi
done

# Execute user scripts
# Determine the target user for user-specific scripts
TARGET_USER=""
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
elif [[ "$EUID" -eq 0 && -z "${SUDO_USER:-}" ]]; then
    # If run directly as root (e.g. sudo su), SUDO_USER might not be set.
    # Try to get a logged-in user. This is a fallback and might not be robust.
    # The user scripts themselves have better checks.
    TARGET_USER=$(logname 2>/dev/null || whoami)
    if [[ "$TARGET_USER" == "root" ]]; then
         echo "[run-all] Warning: Running as root and SUDO_USER is not set. User scripts might not run correctly or for the intended user."
         echo "[run-all] It's highly recommended to run 'run-all.sh' via 'sudo ./run-all.sh' from a normal user session."
         if [[ -z "$DRY_RUN_FLAG" ]]; then
            echo "[run-all] You should manually run user scripts (09, 10, 11) as the intended user."
         fi
    fi
else
    # Running as non-root (only possible if dry-run was specified and root check was bypassed)
    TARGET_USER=$(whoami)
    echo "[run-all] Running user scripts as current user '$TARGET_USER' (dry-run mode as non-root)."
fi


if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]] && [[ -z "$DRY_RUN_FLAG" ]]; then
    echo "[run-all] Critical: Cannot determine a non-root user to run user-specific scripts (09, 10, 11)."
    echo "[run-all] Please ensure SUDO_USER is available (run via 'sudo ./run-all.sh') or run these scripts manually."
else
    for script_name in "${USER_SCRIPTS[@]}"; do
        script_path="$SCRIPT_DIR/$script_name"
        if [[ -f "$script_path" ]]; then
            echo ""
            echo "[run-all] === Running $script_name (as user: $TARGET_USER) ==="
            if [[ -n "$DRY_RUN_FLAG" ]]; then
                echo "DRY-RUN (as user $TARGET_USER) ➜ sudo -u \"$TARGET_USER\" \"$script_path\" $DRY_RUN_FLAG"
            else
                # Ensure the target user exists before attempting to run as them
                if id -u "$TARGET_USER" >/dev/null 2>&1; then
                    sudo -u "$TARGET_USER" "$script_path" $DRY_RUN_FLAG
                else
                    echo "[run-all] Error: User '$TARGET_USER' does not exist. Cannot run $script_name."
                    echo "[run-all] Please ensure the user environment is correctly set up or run this script manually as the target user."
                fi
            fi
            echo "[run-all] === Completed $script_name ==="
        else
            echo "[run-all] Warning: User script $script_name not found. Skipping."
        fi
    done
fi

echo ""
echo "[run-all] All applicable scripts executed."
