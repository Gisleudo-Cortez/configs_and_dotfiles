#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script installs packages and needs root
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
        eval "$*"
    fi
}

echo "[02-official-packages] Preparing to install consolidated list of official packages..."

PKGS=(
    # Shells, Terminals, Editors
    fish starship kitty alacritty neovim vim git stow

    # GUI Apps & File Managers
    dolphin dbeaver vlc thunderbird kate konsole obsidian obs-studio

    # Development & Runtimes
    nodejs npm postgresql cmake go cargo delve gopls git

    # Utilities & Tools
    qalculate-gtk kdeconnect rclone
    fzf bat eza ripgrep ripgrep-all ugrep htop yazi hyperfine
    paru # AUR helper, assuming it's in chaotic-aur

    # Fonts
    ttf-jetbrains-mono ttf-nerd-fonts-symbols

    # Containerization
    docker docker-buildx
)

# Brave Browser handling
BRAVE_PACKAGE_CANDIDATES=("brave-bin" "brave-browser" "brave")
BRAVE_TO_INSTALL=""
if [[ "$DRY_RUN" == true ]]; then
    echo "[02-official-packages] DRY-RUN: Would check for Brave browser package."
    PKGS+=("brave (selected candidate)")
else
    for pkg_candidate in "${BRAVE_PACKAGE_CANDIDATES[@]}"; do
        if pacman -Si "$pkg_candidate" &>/dev/null; then
            echo "[02-official-packages] Found Brave browser candidate: $pkg_candidate"
            BRAVE_TO_INSTALL="$pkg_candidate"
            PKGS+=("$BRAVE_TO_INSTALL")
            break
        fi
    done
    if [[ -z "$BRAVE_TO_INSTALL" ]]; then
        echo "[02-official-packages] Note: Brave browser not found in configured repositories. Consider installing via paru."
    fi
fi

echo "[02-official-packages] Installing packages: ${PKGS[*]}"
run_cmd "pacman -S --needed --noconfirm ${PKGS[*]}"

# Docker post-install setup
echo "[02-official-packages] Configuring Docker..."
run_cmd "systemctl enable --now docker.service"
run_cmd "systemctl enable --now containerd.service"
SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null)
fi
if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[02-official-packages] Adding user '$SUDO_USER_EFFECTIVE' to 'docker' group..."
        run_cmd "usermod -aG docker \"$SUDO_USER_EFFECTIVE\""
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
    PG_INIT_REQUIRED=true # Assume init is required unless a valid data dir is found
    PG_INIT_SUCCESS=false

    echo "[02-official-packages] Enabling PostgreSQL service (to start on boot)..."
    run_cmd "systemctl enable postgresql.service"

    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ Would check PostgreSQL data directory '$PG_DATA_DIR' and initialize if needed."
        PG_INIT_REQUIRED=false # For dry run, assume it might be okay or would be init'd
        PG_INIT_SUCCESS=true
    else
        if [[ -d "$PG_DATA_DIR" ]]; then
            echo "[02-official-packages] PostgreSQL data directory '$PG_DATA_DIR' already exists."
            # Check for PG_VERSION file to see if it's an initialized cluster
            if [[ -f "$PG_DATA_DIR/PG_VERSION" ]]; then
                echo "[02-official-packages] Found '$PG_DATA_DIR/PG_VERSION'. Assuming directory is correctly initialized. Skipping initdb."
                # Ensure ownership and permissions are correct even if directory exists
                run_cmd "chown -R postgres:postgres \"$PG_DATA_DIR\""
                run_cmd "chmod -R 700 \"$PG_DATA_DIR\""
                PG_INIT_REQUIRED=false
                PG_INIT_SUCCESS=true # Valid existing directory
            else
                echo "[02-official-packages] '$PG_DATA_DIR/PG_VERSION' not found. Directory exists but seems uninitialized or corrupt."
                echo "[02-official-packages] WARNING: Removing existing '$PG_DATA_DIR' to allow fresh initialization."
                run_cmd "rm -rf \"$PG_DATA_DIR\""
                # PG_INIT_REQUIRED remains true, will fall through to initdb block
            fi
        fi

        if [[ "$PG_INIT_REQUIRED" == true ]]; then
            echo "[02-official-packages] Initializing PostgreSQL database cluster (initdb)..."
            run_cmd "mkdir -p \"$PG_DATA_DIR\""
            run_cmd "chown postgres:postgres \"$PG_DATA_DIR\""
            run_cmd "chmod 700 \"$PG_DATA_DIR\""
            
            echo "[02-official-packages] Attempting to initialize PostgreSQL database cluster as user 'postgres'..."
            if sudo -iu postgres bash -c "initdb --locale=C.UTF-8 -E UTF8 -D \"$PG_DATA_DIR\""; then
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
        run_cmd "systemctl start postgresql.service"
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
