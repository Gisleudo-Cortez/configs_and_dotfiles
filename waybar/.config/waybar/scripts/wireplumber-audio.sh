#!/bin/bash
# Waybar Wireplumber Audio Controller
# Notifications: hyprctl notify (no daemon needed)
# Sink selection:  wofi --dmenu

NOTIFICATION_TIMEOUT=3000  # ms

# hyprctl notify <icon> <timeout_ms> <color> <message>
# icon: 0=info, 1=warning, 2=error, 3=hint
notify() {
    local msg="$1"
    hyprctl notify 0 "$NOTIFICATION_TIMEOUT" "rgb(88,166,255)" "  Audio: $msg" 2>/dev/null
}

# Returns current volume as integer 0-100
get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | awk '{printf "%d", $2 * 100}'
}

# Returns 1 if muted, 0 if not
is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | grep -c "MUTED"
}

# Prints lines of: id|name
list_sinks() {
    wpctl status 2>/dev/null \
        | awk '/Sinks:/,/Sources:/' \
        | grep -E '[0-9]+\.' \
        | awk '{
            for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.$/) {
                id = substr($i, 1, length($i)-1)
                name = ""
                for(j=i+1; j<=NF; j++) {
                    if ($j ~ /^\[/) break
                    name = name (j>i+1 ? " " : "") $j
                }
                print id "|" name
                break
            }
        }'
}

# Returns numeric ID of current default sink
get_default_sink_id() {
    wpctl status 2>/dev/null \
        | awk '/Sinks:/,/Sources:/' \
        | grep '\*' \
        | awk '{
            for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.$/) {
                print substr($i, 1, length($i)-1); exit
            }
        }'
}

# Returns human-readable name of default sink
get_default_sink_name() {
    wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
        | grep -E 'node\.nick|node\.description' \
        | head -1 \
        | awk -F'"' '{print $2}'
}

# Select sink via wofi, switch with wpctl
select_sink() {
    local current_id
    current_id=$(get_default_sink_id)

    # Build parallel arrays: display labels and IDs
    local -a labels ids
    while IFS='|' read -r id name; do
        ids+=("$id")
        if [[ "$id" == "$current_id" ]]; then
            labels+=(" [active]  $name")
        else
            labels+=("   $name")
        fi
    done < <(list_sinks)

    [[ ${#labels[@]} -eq 0 ]] && notify "No sinks found" && return

    # Show wofi menu
    local selected
    selected=$(printf '%s\n' "${labels[@]}" | wofi \
        --dmenu \
        --width=380 \
        --height=250 \
        --prompt="Audio Output:" \
        --cache-file=/dev/null)

    [[ -z "$selected" ]] && return

    # Match selected label back to ID by index
    local i
    for i in "${!labels[@]}"; do
        if [[ "${labels[$i]}" == "$selected" ]]; then
            wpctl set-default "${ids[$i]}"
            # Strip label prefix to get clean name
            local name="${selected#* }"   # drop icon
            name="${name#\[active\]  }"  # drop [active] if present
            notify "Switched to $name"
            return
        fi
    done
}

# Toggle mute
toggle_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if [[ "$(is_muted)" -gt 0 ]]; then
        notify "Muted"
    else
        notify "Unmuted — $(get_volume)%"
    fi
}

# Adjust volume: "+" or "-"
adjust_volume() {
    local step="${1:-5}"
    local direction="${2:-+}"
    wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ "${step}%${direction}"
}

# Waybar display string
get_sink_display() {
    local vol muted icon name
    vol=$(get_volume)
    muted=$(is_muted)

    if [[ "$muted" -gt 0 ]]; then
        icon="󰝟"
    elif [[ "$vol" -lt 33 ]]; then
        icon="󰕿"
    elif [[ "$vol" -lt 67 ]]; then
        icon="󰖀"
    else
        icon="󰕾"
    fi

    name=$(get_default_sink_name)
    printf "%s %d%% (%s)" "$icon" "$vol" "${name:-Default}"
}

case "${1:-display}" in
    display)     get_sink_display ;;
    select)      select_sink ;;
    toggle-mute) toggle_mute ;;
    up)          adjust_volume 5 "+"; get_sink_display ;;
    down)        adjust_volume 5 "-"; get_sink_display ;;
esac
