#!/usr/bin/env bash
# Shared helper functions for installation scripts

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly."
    exit 1
fi

# --- Logging and Command Execution ---

# Run commands safely; respects DRY_RUN.
run_cmd() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

# Run commands as the non-root user.
# Fix: Checks if we are already that user to avoid nested/redundant sudo calls.
run_cmd_user() {
    local target_user="${SUDO_USER:-$(whoami)}"
    local current_user
    current_user=$(whoami)

    # Use arguments as the command description
    local cmd_str="$*"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "DRY-RUN (as user: ${target_user}) ➜ $cmd_str"
    else
        echo "EXECUTING (as user: ${target_user}) ➜ $cmd_str"
        if [[ "$current_user" == "$target_user" ]]; then
            # We are already the correct user; run directly
            "$@"
        else
            # We are (presumably) root; drop privileges
            sudo -u "${target_user}" --preserve-env=PATH,HOME -- "$@"
        fi
    fi
}

# --- Pre-flight Checks ---

need_root() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}")
    if [[ "${EUID}" -ne 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            echo "[${script_name}] Warning: Not running as root, but continuing in dry-run mode."
        else
            echo "[${script_name}] Error: This script must be run as root (use sudo)."
            exit 1
        fi
    fi
}

need_user() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}")
    if [[ "${EUID}" -eq 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            echo "[${script_name}] Warning: Running as root in dry-run mode, but this script is intended for a regular user."
        else
            echo "[${script_name}] Error: This script must be run as a regular user, not as root."
            exit 1
        fi
    fi
}
