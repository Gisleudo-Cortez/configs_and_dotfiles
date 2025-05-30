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
        "$@" # Changed from eval "$*"
    fi
}

echo "[02-official-packages] Preparing to install consolidated list of official packages..."

# Initial list + packages from installed_files.txt (official/chaotic-aur)
# List curated from installed_files.txt, duplicates with original list are implicitly handled by pacman --needed
# Some packages from installed_files.txt might be specific to Garuda edition and could be pruned if not desired.
PKGS=(
    # Shells, Terminals, Editors from original
    fish starship kitty alacritty neovim vim git stow

    # GUI Apps & File Managers from original
    dolphin dbeaver vlc thunderbird kate konsole obsidian obs-studio

    # Development & Runtimes from original
    nodejs npm postgresql cmake go cargo delve gopls

    # Utilities & Tools from original
    qalculate-gtk kdeconnect rclone
    fzf bat eza ripgrep ripgrep-all ugrep htop yazi hyperfine
    paru # AUR helper, assuming it's in chaotic-aur

    # Fonts from original
    "ttf-jetbrains-mono" "ttf-nerd-fonts-symbols" # Explicitly quoted for clarity if needed anywhere else

    # Containerization from original
    docker docker-buildx

    # Packages from installed_files.txt 
    "7zip" alsa-firmware alsa-utils appmenu-gtk-module ark base base-devel bash-completion
    bind blueman bluetooth-autoconnect bridge-utils btrfs-progs bzip2
    chromium cliphist code coreutils cryptsetup curlftpfs deluge-gtk dialog dmidecode dmraid dosfstools
    downgrade dracut dua-cli dunst dust e2fsprogs ecryptfs-utils efibootmgr eog ethtool evince exfatprogs
    f2fs-tools fastfetch fatresize ffmpegthumbnailer ffmpegthumbs file file-roller filesystem findutils
    firefox foot freetype2 fscrypt fsearch fwupd galculator gcc-libs geany gestures gettext gimp
    glibc gnome-firmware gnome-keyring gnome-logs gnome-system-monitor gnu-netcat gparted grep
    grim grub grub-btrfs gsimplecal gstreamer-meta gtk-engine-murrine gvfs gvfs-afc gvfs-gphoto2
    gvfs-mtp gvfs-nfs gvfs-smb gzip handbrake hyperfine hypridle hyprland hyprpicker hyprsunset
    inetutils input-devices-support intel-ucode inxi iproute2 iptables-nft iputils jfsutils jq kanshi
    kde-cli-tools keepassxc kvantum lhasa lib32-pipewire-jack libdvdcss libgsf libmythes libopenraw
    libreoffice-still librsvg libva-nvidia-driver licenses linux-firmware linux-hardened linux-hardened-headers
    linux-zen linux-zen-headers logrotate lrzip lsb-release lvm2 lxappearance lzip lzop mako man-db man-pages
    mdadm meld memtest86+ mesa-utils micro modem-manager-gui mtools nano ncdu net-tools
    network-manager-applet networkmanager-support nfs-utils nilfs-utils nm-connection-editor nmap
    noto-fonts noto-fonts-cjk noto-fonts-emoji nss-mdns ntfs-3g nushell nwg-displays nwg-drawer
    nwg-launchers nwg-look openxr os-prober-btrfs otf-font-awesome otf-font-awesome-4 pacman pacman-contrib
    pacseek pamixer parallel pavucontrol pciutils perl-file-mimeinfo pipewire-jack pipewire-support
    plasma-framework5 playerctl plocate polkit-gnome powertop printer-support procps-ng psmisc qbittorrent
    qt5-imageformats qt5ct qt6ct ranger rate-mirrors rsync rust samba-support satty scanner-support
    sdbus-cpp sddm sed shadow simple-scan slurp snapper-support snapper-tools sof-firmware sshfs
    steam-native-runtime sudo swappy swaylock swww system-config-printer systemd systemd-sysvcompat tar
    terminus-font thunar traceroute ttf-dejavu ttf-fantasque-sans-mono ttf-fira-sans ttf-firacode-nerd
    ttf-liberation ttf-opensans ttf-ubuntu-font-family udiskie ufw unace unarchiver unarj unrar unzip
    update-grub usbutils util-linux uwsm vi virt-manager-meta waybar wayland wayland-protocols-git
    wayland-utils wdisplays wget which whois wine wireless-regdb wireless_tools wireplumber wlogout wofi
    wpaperd wqy-zenhei wtype xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland
    xdg-user-dirs xdg-utils xfce4-terminal xfsprogs xorg-xhost xorg-xwayland xsel xz
    zip
)

# Brave Browser handling
BRAVE_PACKAGE_CANDIDATES=("brave-bin" "brave-browser" "brave") 
BRAVE_TO_INSTALL=""
if [[ "$DRY_RUN" == true ]]; then
    echo "[02-official-packages] DRY-RUN: Would check for Brave browser package."
    # Add a placeholder or one of the candidates for dry run output
    PKGS_TO_INSTALL_BRAVE_DRY_RUN=("brave (selected candidate)")
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
elif [[ "$DRY_RUN" == true ]]; then
    PACKAGES_FINAL_LIST+=("${PKGS_TO_INSTALL_BRAVE_DRY_RUN[@]}")
fi


# Remove duplicates just in case (pacman --needed handles it but cleaner list for echo)
UNIQUE_PKGS_FINAL_LIST=($(echo "${PACKAGES_FINAL_LIST[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

echo "[02-official-packages] Attempting to install/update the following packages: ${UNIQUE_PKGS_FINAL_LIST[*]}"
run_cmd pacman -S --needed --noconfirm "${UNIQUE_PKGS_FINAL_LIST[@]}"


# Docker post-install setup
echo "[02-official-packages] Configuring Docker..."
run_cmd systemctl enable --now docker.service
run_cmd systemctl enable --now containerd.service # Ensure containerd is also explicitly enabled
SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null || echo "") # Fallback if logname fails
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

# PostgreSQL post-install setup
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
                run_cmd mv "$PG_DATA_DIR" "$BACKUP_PG_DATA_DIR" # Changed from rm -rf
            fi
        fi

        if [[ "$PG_INIT_REQUIRED" == true ]]; then
            echo "[02-official-packages] Initializing PostgreSQL database cluster (initdb)..."
            run_cmd mkdir -p "$PG_DATA_DIR"
            run_cmd chown postgres:postgres "$PG_DATA_DIR"
            run_cmd chmod 700 "$PG_DATA_DIR"
            
            echo "[02-official-packages] Attempting to initialize PostgreSQL database cluster as user 'postgres'..."
            # Use su for more compatibility than sudo -iu if postgres user has no proper shell temporarily
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
