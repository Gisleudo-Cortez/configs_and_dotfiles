#!/bin/bash
# Re-apply monitor rules from monitors_positioning.conf at runtime via
# hyprctl keyword monitor, without triggering a full config reload.
# Avoids the known hyprctl reload bug that wakes up previously-disabled monitors.

CONFIG="$HOME/.config/hypr/monitors_positioning.conf"

while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# || -z "${line//[[:space:]]/}" ]] && continue
    if [[ "$line" =~ ^monitor=(.+)$ ]]; then
        hyprctl keyword monitor "${BASH_REMATCH[1]}"
    fi
done < "$CONFIG"

notify-send -t 1500 "Displays" "Monitor config reloaded"
