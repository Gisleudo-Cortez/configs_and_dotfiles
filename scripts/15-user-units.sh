#!/usr/bin/env bash
set -euo pipefail

# Enable user systemd units that stow deploys but cannot enable.
# Unit FILES live in stow packages (ollama, mcp-http, email-digest, ...);
# enablement is runtime state (target.wants symlinks) that must be recreated
# on every rebuild. Idempotent: safe to run any number of times.

source "$(dirname "$0")/helpers.sh"

need_user

# --- Configuration ---
# (unit, enable-target) pairs. Timers enable into timers.target; plain
# services into default.target. Keylight/openrgb units are project-anchored
# symlinks, not stow-managed — enabled here so their wiring survives rebuilds.
UNITS_TO_ENABLE=(
    "ollama.service default.target"
    "mcp-http.service default.target"
    "email-digest.timer timers.target"
    "keylight.service default.target"
    "openrgb-server.service default.target"
)

# Deliberate masks: dunst is replaced by mako as the notification daemon.
# An unmasked dunst (reinstalled by packages-official.txt on rebuild) would
# fight mako for the D-Bus notification name.
UNITS_TO_MASK=(
    "dunst.service"
)

main() {
    for entry in "${UNITS_TO_ENABLE[@]}"; do
        unit="${entry%% *}"
        target="${entry##* }"
        if [[ -e "${HOME}/.config/systemd/user/${unit}" ]]; then
            echo "[15-user-units] Enabling ${unit} into ${target}"
            run_cmd_user systemctl --user enable "${unit}"
        else
            echo "[15-user-units] Warning: unit '${unit}' not deployed — skipping (enable after its package is stowed)."
        fi
    done

    for unit in "${UNITS_TO_MASK[@]}"; do
        echo "[15-user-units] Masking ${unit}"
        run_cmd_user systemctl --user mask "${unit}"
    done

    if [[ "${DRY_RUN:-false}" != true ]]; then
        run_cmd_user systemctl --user daemon-reload
    fi

    echo "[15-user-units] User unit enablement complete."
}

main