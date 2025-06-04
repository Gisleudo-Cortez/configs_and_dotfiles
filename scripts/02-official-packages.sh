#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[02-official-packages] Warning: Not running as root, but continuing in dry-run mode."
    else
        echo "[02-official-packages] Error: This script must be run as root."
        exit 1
    fi
fi

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

echo "[02-official-packages] Preparing to install/update official packages..."

# Combined and updated package list
PKGS=(
    # Shells, Terminals, Editors
    fish starship kitty alacritty neovim vim git stow zsh

    # GUI Apps & File Managers
    dolphin dbeaver vlc thunderbird kate konsole obsidian obs-studio firefox ark libreoffice-fresh-pt-br

    # Development & Runtimes
    nodejs npm postgresql cmake go cargo delve gopls

    # Utilities & Tools
    qalculate-gtk kdeconnect rclone
    fzf bat eza ripgrep ripgrep-all ugrep htop yazi hyperfine
    paru jq grim slurp swappy dunst swaylock hypridle rofi-wayland
    brightnessctl playerctl udiskie unzip pacman-contrib parallel
    imagemagick libnotify duf fastfetch cliphist

    # Fonts
    ttf-jetbrains-mono  # Base JetBrains Mono
    nerd-fonts          # Group for all Nerd Fonts (includes FiraCode, symbols, etc.)
    noto-fonts          # Main Noto family
    noto-fonts-cjk      # Noto CJK (Chinese, Japanese, Korean)
    noto-fonts-emoji    # Noto Color Emoji
    noto-fonts-extra    # Additional Noto fonts
    gsfonts             # Ghostscript fonts (URW, Nimbus, etc.)
    ttf-fira-sans       # Fira Sans family
    adwaita-fonts       # Adwaita (GNOME UI font)
    ttf-dejavu          # DejaVu family
    ttf-liberation      # Liberation fonts
    terminus-font       # Terminus bitmap font
    adobe-source-code-pro-fonts # Adobe Source Code Pro
    ttf-ubuntu-font-family    # Ubuntu font family
    cantarell-fonts     # Cantarell (GNOME font)
    wqy-zenhei          # WenQuanYi Zen Hei (CJK)
    otf-font-awesome    # Font Awesome icons (version 6)
    ttf-fantasque-sans-mono # Fantasque Sans Mono (non-Nerd version)
    ttf-opensans        # Open Sans family

    # Containerization
    docker docker-buildx

    # System & Audio
    pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse
    gst-plugin-pipewire wireplumber pavucontrol pamixer

    # Networking & Bluetooth
    networkmanager network-manager-applet bluez bluez-utils blueman

    # Display Manager (SDDM)
    sddm qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects

    # Window Manager Related (Hyprland ecosystem)
    swww wlogout hyprpicker

    # Desktop Integration & Dependencies
    polkit-gnome xdg-desktop-portal-gtk xdg-user-dirs
    qt5-imageformats ffmpegthumbs kde-cli-tools

    # Theming
    nwg-look qt5ct qt6ct kvantum qt5-wayland qt6-wayland

    # Other Applications
    nwg-displays
)

# Brave Browser handling (remains the same)
BRAVE_PACKAGE_CANDIDATES=("brave-bin" "brave-browser" "brave")
BRAVE_TO_INSTALL=""
if [[ "$DRY_RUN" == true ]]; then
    echo "[02-official-packages] DRY-RUN: Would check for Brave browser package."
    # Add a placeholder or one of the candidates for dry run output
    PACKAGES_TO_INSTALL_BRAVE_DRY_RUN=("brave (selected candidate)")
else
    for pkg_candidate in "${BRAVE_PACKAGE_CANDIDATES[@]}"; do
        if pacman -Si "$pkg_candidate" &>/dev/null; then
            echo "[02-official-packages] Found Brave browser candidate: $pkg_candidate"
            BRAVE_TO_INSTALL="$pkg_candidate"
            break
        fi
    done
    if [[ -z "$BRAVE_TO_INSTALL" ]]; then
        echo "[02-official-packages] Note: Brave browser not found in configured repositories. Consider installing via paru."
    fi
fi

# Combine main packages with Brave if found
PACKAGES_FINAL_LIST=("${PKGS[@]}")
if [[ -n "$BRAVE_TO_INSTALL" ]]; then
    PACKAGES_FINAL_LIST+=("$BRAVE_TO_INSTALL")
elif [[ "$DRY_RUN" == true && "${#PACKAGES_TO_INSTALL_BRAVE_DRY_RUN[@]}" -gt 0 ]]; then
    PACKAGES_FINAL_LIST+=("${PACKAGES_TO_INSTALL_BRAVE_DRY_RUN[@]}")
fi

# Remove duplicates and sort for cleaner output and deterministic behavior
UNIQUE_PKGS_FINAL_LIST=($(echo "${PACKAGES_FINAL_LIST[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

echo "[02-official-packages] Attempting to install/update the following packages: ${UNIQUE_PKGS_FINAL_LIST[*]}"
run_cmd pacman -S --needed --noconfirm "${UNIQUE_PKGS_FINAL_LIST[@]}"


# Docker post-install setup (remains the same)
echo "[02-official-packages] Configuring Docker..."
run_cmd systemctl enable --now docker.service
run_cmd systemctl enable --now containerd.service
SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null || echo "")
fi
if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[02-official-packages] Adding user '$SUDO_USER_EFFECTIVE' to 'docker' group..."
        run_cmd usermod -aG docker "$SUDO_USER_EFFECTIVE"
        echo "[02-official-packages] User '$SUDO_USER_EFFECTIVE' added to 'docker' group. Re-login required."
    else
        echo "[02-official-packages] Warning: SUDO_USER '$SUDO_USER_EFFECTIVE' invalid. Skipping add to docker group."
    fi
else
    echo "[02-official-packages] Note: Could not determine non-root user for docker group. Add manually if needed."
fi

# PostgreSQL post-install setup (remains the same)
echo "[02-official-packages] Configuring PostgreSQL..."
if pacman -Qs postgresql &>/dev/null; then
    PG_DATA_DIR="/var/lib/postgres/data"
    PG_INIT_REQUIRED=true
    PG_INIT_SUCCESS=false

    echo "[02-official-packages] Enabling PostgreSQL service (to start on boot)..."
    run_cmd systemctl enable postgresql.service

    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ Would check PostgreSQL data directory '$PG_DATA_DIR' and initialize if needed."
        PG_INIT_REQUIRED=false
        PG_INIT_SUCCESS=true
    else
        if [[ -d "$PG_DATA_DIR" ]]; then
            echo "[02-official-packages] PostgreSQL data directory '$PG_DATA_DIR' already exists."
            if [[ -f "$PG_DATA_DIR/PG_VERSION" ]]; then
                echo "[02-official-packages] Found '$PG_DATA_DIR/PG_VERSION'. Assuming directory is correctly initialized. Skipping initdb."
                run_cmd chown -R postgres:postgres "$PG_DATA_DIR"
                run_cmd chmod -R 700 "$PG_DATA_DIR"
                PG_INIT_REQUIRED=false
                PG_INIT_SUCCESS=true
            else
                echo "[02-official-packages] '$PG_DATA_DIR/PG_VERSION' not found. Directory exists but seems uninitialized or corrupt."
                BACKUP_PG_DATA_DIR="${PG_DATA_DIR}.bak.$(date +%Y%m%d%H%M%S)"
                echo "[02-official-packages] WARNING: Moving existing '$PG_DATA_DIR' to '$BACKUP_PG_DATA_DIR' to allow fresh initialization."
                run_cmd mv "$PG_DATA_DIR" "$BACKUP_PG_DATA_DIR"
            fi
        fi

        if [[ "$PG_INIT_REQUIRED" == true ]]; then
            echo "[02-official-packages] Initializing PostgreSQL database cluster (initdb)..."
            run_cmd mkdir -p "$PG_DATA_DIR"
            run_cmd chown postgres:postgres "$PG_DATA_DIR"
            run_cmd chmod 700 "$PG_DATA_DIR"
            
            echo "[02-official-packages] Attempting to initialize PostgreSQL database cluster as user 'postgres'..."
            if su - postgres -s /bin/bash -c "initdb --locale=C.UTF-8 -E UTF8 -D '$PG_DATA_DIR'"; then
                 echo "[02-official-packages] PostgreSQL database cluster initialized successfully by initdb command."
                 PG_INIT_SUCCESS=true
            else
                 echo "[02-official-packages] Error: 'initdb' command FAILED with exit code $?."
                 echo "[02-official-packages] PostgreSQL Service will not be started."
                 PG_INIT_SUCCESS=false
            fi
        fi
    fi

    if [[ "$PG_INIT_SUCCESS" == true ]]; then
        echo "[02-official-packages] Attempting to start PostgreSQL service..."
        run_cmd systemctl start postgresql.service
        if [[ "$DRY_RUN" == false ]]; then
            sleep 3
            if systemctl is-active --quiet postgresql.service; then
                echo "[02-official-packages] PostgreSQL service started successfully."
            else
                echo "[02-official-packages] Error: PostgreSQL service FAILED to start after initialization/check."
                echo "[02-official-packages] Please check logs: sudo systemctl status postgresql.service AND sudo journalctl -xeu postgresql.service"
            fi
        else
             echo "DRY-RUN ➜ Would check 'systemctl is-active --quiet postgresql.service'."
        fi
    else
        echo "[02-official-packages] PostgreSQL service start SKIPPED due to previous errors or failed initdb."
    fi
else
    echo "[02-official-packages] PostgreSQL not in package list or not installed. Skipping PostgreSQL configuration."
fi

echo "[02-official-packages] Package installation and basic service configuration complete."
