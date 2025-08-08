#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# --- Package Lists ---

get_packages() {
    local pkgs=(
        # Shells, Terminals, Editors
        fish starship kitty alacritty neovim vim git stow zsh
        # GUI Apps & File Managers
        dolphin dbeaver vlc thunderbird kate konsole obsidian obs-studio firefox ark libreoffice-fresh-pt-br
        # Development & Runtimes
        nodejs npm postgresql cmake go cargo delve gopls
        # Utilities & Tools
        qalculate-gtk kdeconnect rclone rsync 7zip
        fzf bat eza ripgrep ripgrep-all ugrep htop yazi hyperfine qt6-virtualkeyboard
        paru jq grim slurp swappy dunst swaylock hypridle rofi-wayland
        brightnessctl playerctl udiskie unzip pacman-contrib parallel
        imagemagick libnotify duf fastfetch cliphist yad python-pywal
        # Fonts
        ttf-jetbrains-mono nerd-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
        gsfonts ttf-fira-sans adwaita-fonts ttf-dejavu ttf-liberation terminus-font
        adobe-source-code-pro-fonts ttf-ubuntu-font-family cantarell-fonts wqy-zenhei
        otf-font-awesome ttf-fantasque-sans-mono ttf-opensans
        # Containerization
        docker docker-buildx fuse-overlayfs iptables-nft
        # System & Audio
        pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse
        gst-plugin-pipewire wireplumber pavucontrol pamixer
        # Networking & Bluetooth
        networkmanager network-manager-applet iwd bluez bluez-utils blueman
        # Display Manager (SDDM)
        sddm qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects
        # Window Manager Related (Hyprland ecosystem)
        swww wlogout hyprpicker
        # Desktop Integration & Dependencies
        polkit-gnome xdg-desktop-portal-gtk xdg-user-dirs archlinux-xdg-menu
        qt5-imageformats ffmpegthumbs kde-cli-tools
        # Theming
        nwg-look qt5ct qt6ct kvantum qt5-wayland qt6-wayland
        # Other Applications
        nwg-displays
    )
    echo "${pkgs[@]}"
}

# --- Installation Functions ---

install_packages() {
    local pkgs_to_install=("$@")
    echo "[02-official-packages] Attempting to install/update official packages..."
    run_cmd pacman -S --needed --noconfirm "${pkgs_to_install[@]}"
}

configure_docker() {
    echo "[02-official-packages] Configuring Docker..."

    # Ensure required kernel modules are loaded for Docker.
    echo "[02-official-packages] Ensuring kernel modules for Docker are configured and loaded..."
    local docker_modules_conf="/etc/modules-load.d/docker.conf"
    run_cmd bash -c "printf 'overlay\niptable_nat\n' > '$docker_modules_conf'"
    run_cmd modprobe overlay
    run_cmd modprobe iptable_nat

    # Enable and start container services.
    run_cmd systemctl enable --now containerd.service
    run_cmd systemctl enable --now docker.service
    
    local sudo_user
    sudo_user="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
    
    if [[ -n "$sudo_user" && "$sudo_user" != "root" ]]; then
        if id -u "$sudo_user" &>/dev/null; then
            echo "[02-official-packages] Adding user '$sudo_user' to 'docker' group..."
            run_cmd usermod -aG docker "$sudo_user"
            echo "[02-official-packages] User '$sudo_user' added to 'docker' group. Re-login required."
        else
            echo "[02-official-packages] Warning: SUDO_USER '$sudo_user' invalid. Skipping add to docker group."
        fi
    else
        echo "[02-official-packages] Note: Could not determine non-root user for docker group. Add manually if needed."
    fi
}

configure_postgresql() {
    if ! pacman -Qs postgresql &>/dev/null; then
        echo "[02-official-packages] PostgreSQL not installed. Skipping configuration."
        return
    fi

    echo "[02-official-packages] Configuring PostgreSQL..."
    local pg_data_dir="/var/lib/postgres/data"
    
    run_cmd systemctl enable postgresql.service

    if [[ -d "$pg_data_dir" && -f "$pg_data_dir/PG_VERSION" ]]; then
        echo "[02-official-packages] PostgreSQL data directory seems initialized. Ensuring permissions."
        run_cmd chown -R postgres:postgres "$pg_data_dir"
        run_cmd chmod -R 700 "$pg_data_dir"
    else
        if [[ -d "$pg_data_dir" ]]; then
            local backup_dir="${pg_data_dir}.bak.$(date +%Y%m%d%H%M%S)"
            echo "[02-official-packages] WARNING: Moving existing '$pg_data_dir' to '$backup_dir'."
            run_cmd mv "$pg_data_dir" "$backup_dir"
        fi
        
        echo "[02-official-packages] Initializing PostgreSQL database cluster..."
        run_cmd mkdir -p "$pg_data_dir"
        run_cmd chown postgres:postgres "$pg_data_dir"
        run_cmd chmod 700 "$pg_data_dir"
        
        if run_cmd su - postgres -s /bin/bash -c "initdb --locale=C.UTF-8 -E UTF8 -D '$pg_data_dir'"; then
            echo "[02-official-packages] PostgreSQL database cluster initialized successfully."
        else
            echo "[02-official-packages] Error: 'initdb' command FAILED. PostgreSQL service will not be started."
            return
        fi
    fi

    echo "[02-official-packages] Starting PostgreSQL service..."
    run_cmd systemctl start postgresql.service
    if [[ "$DRY_RUN" == false ]]; then
        sleep 3
        if ! systemctl is-active --quiet postgresql.service; then
            echo "[02-official-packages] Error: PostgreSQL service FAILED to start."
        fi
    fi
}

configure_networkmanager() {
    echo "[02-official-packages] Configuring NetworkManager with iwd backend..."
    local nm_conf_dir="/etc/NetworkManager/conf.d"
    local nm_wifi_backend_conf="$nm_conf_dir/wifi_backend.conf"
    local wifi_backend_content="[device]\nwifi.backend=iwd"

    run_cmd mkdir -p "$nm_conf_dir"
    run_cmd bash -c "echo -e '$wifi_backend_content' > '$nm_wifi_backend_conf'"
    run_cmd chmod 644 "$nm_wifi_backend_conf"

    run_cmd systemctl enable --now NetworkManager.service
    run_cmd systemctl enable --now iwd.service

    local services_to_disable=("wpa_supplicant.service" "systemd-networkd.service" "systemd-networkd.socket")
    for service in "${services_to_disable[@]}"; do
        if systemctl list-unit-files --type=service | grep -q "^${service}" || systemctl list-unit-files --type=socket | grep -q "^${service}"; then
            run_cmd systemctl disable --now "$service"
        fi
    done
}

# --- Main Logic ---

main() {
    # Word-split the output of get_packages into an array
    local all_packages_arr=($(get_packages))

    local brave_pkg
    brave_pkg=$(pacman -Si brave-browser 2>/dev/null && echo "brave-browser" || echo "")

    # Combine the package lists, ensuring brave_pkg is only added if it's not empty
    local final_pkg_list=("${all_packages_arr[@]}")
    if [[ -n "$brave_pkg" ]]; then
        final_pkg_list+=("$brave_pkg")
    fi

    install_packages "${final_pkg_list[@]}"
    configure_docker
    configure_postgresql
    configure_networkmanager

    echo "[02-official-packages] Package installation and basic service configuration complete."
}

main
