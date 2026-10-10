#!/bin/bash
# Lid-safe config reload — Lua-era replacement for the old .conf replay loop.
#
# History: this script re-applied monitor= lines from
# monitors_positioning.conf via `hyprctl keyword monitor` (partial reload,
# avoiding a wake-disabled-monitors bug). On the Lua config (Hyprland
# 0.56.x) `hyprctl keyword` is dead — "keyword can't work with non-legacy
# parsers. Use eval." — and monitors_positioning.conf is superseded by
# monitors.lua, so the replay could only fail and print a false
# "reloaded" notification.
#
# Now: `hyprctl reload` re-reads the Lua config (monitors.lua = single
# source of truth for the connected layout). The known reload side
# effect — waking previously-disabled monitors — is countered by
# re-asserting the lid state right after, mirroring the hyprland.start
# check in hyprland.lua.

hyprctl reload

if grep -q closed /proc/acpi/button/lid/LID1/state 2>/dev/null; then
    hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
fi

notify-send -t 1500 "Displays" "Config reloaded (lid-safe)"