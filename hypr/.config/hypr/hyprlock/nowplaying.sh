#!/usr/bin/env bash
# MPRIS now-playing probe for hyprlock.
# Kept as a script because hyprlang (hyprlock 0.9.6) fails to parse
# playerctl's {{ }} format braces inside a text = cmd[...] value.
# The parse failure makes the label fall back to its default text,
# which renders as "Sample Text" on the lock screen.
playerctl metadata --format '♫ {{ artist }} — {{ title }}' 2>/dev/null || echo ""
