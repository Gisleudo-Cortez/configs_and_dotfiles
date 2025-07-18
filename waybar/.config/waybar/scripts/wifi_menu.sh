#!/bin/bash

# wifi_menu.sh

# Function to display notifications
notify_user() {
    notify-send "Wi-Fi Connection" "$1"
}

# Get a list of available Wi-Fi networks
# Fields: SSID, SIGNAL, SECURITY, IN-USE
mapfile -t networks < <(nmcli --color no -t -f ssid,signal,security,in-use dev wifi list --rescan yes | sed 's/\\:/;/g') # Replace escaped colons for yad

if [ ${#networks[@]} -eq 0 ]; then
    notify_user "No Wi-Fi networks found."
    exit 0
fi

# Prepare networks for YAD dialog (SSID:SIGNAL:SECURITY:IN-USE)
# We add an asterisk to the currently connected network for visual indication
yad_networks=()
current_ssid=""
for line in "${networks[@]}"; do
    IFS=':' read -r ssid signal security in_use <<<"$line"
    # Sanitize SSID for display and command usage if needed (though nmcli usually handles SSIDs well)
    # For YAD, we need to ensure no field separator confusion if SSIDs have colons (handled by sed above)
    
    display_ssid="$ssid"
    if [[ "$in_use" == "*" ]]; then
        display_ssid="$ssid (*)" # Mark active connection
        current_ssid="$ssid"
    fi
    yad_networks+=("$display_ssid" "$signal%" "$security")
done

# Display YAD list dialog
# Returns selected line. Format: SSID (*)|Signal%|Security|
selected_network_info=$(yad --width=500 --height=300 \
                        --title="Available Wi-Fi Networks" \
                        --list \
                        --column="SSID" \
                        --column="Signal" \
                        --column="Security" \
                        "${yad_networks[@]}" --button="Connect:0" --button="Cancel:1")

ret=$?

if [ $ret -eq 1 ] || [ -z "$selected_network_info" ]; then
    notify_user "No network selected."
    exit 0
fi

# Extract the SSID (remove the " (*)" if present)
selected_ssid_display=$(echo "$selected_network_info" | awk -F'|' '{print $1}')
selected_ssid="${selected_ssid_display/ (*)/>}" # Remove the marker

if [ -z "$selected_ssid" ]; then
    notify_user "Could not determine selected SSID."
    exit 1
fi

# If already connected to the selected network, do nothing or notify
if [[ "$selected_ssid" == "$current_ssid" ]]; then
    notify_user "Already connected to $selected_ssid."
    exit 0
fi

# Check if a connection profile for this SSID already exists
if nmcli connection show "$selected_ssid" &>/dev/null; then
    # Connection profile exists, try to bring it up
    if nmcli connection up "$selected_ssid"; then
        notify_user "Successfully connected to $selected_ssid."
    else
        # If 'up' fails, it might be due to incorrect stored password or other issues.
        # For simplicity, we'll try to connect as if it's a new one, which might re-prompt.
        # A more robust solution might delete the old profile or specifically ask to update password.
        notify_user "Could not connect to existing profile for $selected_ssid. Trying as new connection."
        # Proceed to password prompt if needed
    fi
else
    # No existing profile, or 'up' failed and we're treating it as new.
    # Check if the network requires a password (common security types)
    selected_security=$(echo "$selected_network_info" | awk -F'|' '{print $3}')
    if [[ "$selected_security" =~ (WPA|WEP) ]]; then
        password=$(yad --entry \
                        --title="Connect to $selected_ssid" \
                        --text="Enter password for $selected_ssid:" \
                        --hide-text \
                        --button="Connect:0" --button="Cancel:1")
        
        if [ $? -ne 0 ] || [ -z "$password" ]; then
            notify_user "Password entry cancelled or empty."
            exit 1
        fi

        if nmcli dev wifi connect "$selected_ssid" password "$password"; then
            notify_user "Successfully connected to $selected_ssid."
        else
            notify_user "Failed to connect to $selected_ssid."
            exit 1
        fi
    else
        # Open network
        if nmcli dev wifi connect "$selected_ssid"; then
            notify_user "Successfully connected to $selected_ssid."
        else
            notify_user "Failed to connect to $selected_ssid."
            exit 1
        fi
    fi
fi

exit 0
