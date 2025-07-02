#!/usr/bin/env bash
# Shared helper functions for installation scripts

# This script is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly."
    exit 1
fi

# --- Logging and Command Execution ---

# A helper to run commands safely.
# It respects DRY_RUN and prints the command being executed.
# Usage: run_cmd command arg1 "arg 2"
run_cmd() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

# A helper to run commands as the non-root user who invoked sudo.
# Respects DRY_RUN.
# Usage: run_cmd_user command arg1 "arg 2"
run_cmd_user() {
    local target_user="${SUDO_USER:-$(whoami)}"
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "DRY-RUN (as user: ${target_user}) ➜ $*"
    else
        echo "EXECUTING (as user: ${target_user}) ➜ $*"
        sudo -u "${target_user}" --preserve-env=PATH,HOME -- "$@"
    fi
}


# --- Pre-flight Checks ---

# Ensures the script is run as root, exiting if not.
# Respects DRY_RUN.
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

# Ensures the script is run as a regular user, not root.
# Respects DRY_RUN.
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
