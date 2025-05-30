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
        eval "$*" # Changed from "$@" to eval "$*"
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

# Brave Browser handling: check if available in repos (often in chaotic-aur as brave-bin)
BRAVE_PACKAGE_CANDIDATES=("brave-bin" "brave-browser" "brave")
BRAVE_TO_INSTALL=""

if [[ "$DRY_RUN" == true ]]; then
    echo "[02-official-packages] DRY-RUN: Would check for Brave browser package."
    PKGS+=("brave (selected candidate)") # Placeholder for dry run
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
        echo "[02-official-packages] Note: None of the specified Brave browser packages (${BRAVE_PACKAGE_CANDIDATES[*]}) found in configured repositories (including chaotic-aur)."
        echo "[02-official-packages] You might need to install it via 'paru -S brave-bin' or similar after paru is installed, or ensure your repos are correctly set up."
    fi
fi


echo "[02-official-packages] Installing packages: ${PKGS[*]}"
run_cmd "pacman -S --needed --noconfirm ${PKGS[*]}" # Note: PKGS array expansion is fine here with eval

# Docker post-install setup
echo "[02-official-packages] Configuring Docker..."
run_cmd "systemctl enable --now docker.service"
run_cmd "systemctl enable --now containerd.service" # Often started by docker.service

SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null)
fi

if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[02-official-packages] Adding user '$SUDO_USER_EFFECTIVE' to 'docker' group..."
        run_cmd "usermod -aG docker \"$SUDO_USER_EFFECTIVE\""
        echo "[02-official-packages] User '$SUDO_USER_EFFECTIVE' added to 'docker' group. A re-login is required for this to take effect."
    else
        echo "[02-official-packages] Warning: SUDO_USER '$SUDO_USER_EFFECTIVE' does not seem to be a valid user. Skipping add to docker group."
    fi
else
    echo "[02-official-packages] Note: Could not determine a non-root user (SUDO_USER not set or is root)."
    echo "[02-official-packages] If you have a regular user, add them to the 'docker' group manually (e.g., 'sudo usermod -aG docker your_username') to use Docker without sudo."
fi

# PostgreSQL post-install setup
echo "[02-official-packages] Configuring PostgreSQL..."
if pacman -Qs postgresql &>/dev/null; then
    PG_DATA_DIR="/var/lib/postgres/data"
    PG_INIT_SUCCESS=false # Flag to track if initdb was successful or skipped due to existing dir

    echo "[02-official-packages] Enabling PostgreSQL service (to start on boot)..."
    run_cmd "systemctl enable postgresql.service" # Enable first, don't start yet

    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ Would check if PostgreSQL data directory '$PG_DATA_DIR' exists and initialize if not."
        echo "DRY-RUN ➜ sudo -iu postgres bash -c '[ -d \"$PG_DATA_DIR\" ] || { mkdir -p \"$PG_DATA_DIR\" && chown postgres:postgres \"$PG_DATA_DIR\" && chmod 700 \"$PG_DATA_DIR\" && initdb --locale C.UTF-8 -E UTF8 -D \"$PG_DATA_DIR\"; }'"
        PG_INIT_SUCCESS=true # Assume success for dry run to show start command
    else
        # Check if data directory exists
        if [[ ! -d "$PG_DATA_DIR" ]]; then
            echo "[02-official-packages] PostgreSQL data directory '$PG_DATA_DIR' not found. Initializing database cluster..."
            # Create the directory and set permissions before switching to postgres user for initdb
            run_cmd "mkdir -p \"$PG_DATA_DIR\""
            run_cmd "chown postgres:postgres \"$PG_DATA_DIR\""
            run_cmd "chmod 700 \"$PG_DATA_DIR\"" # Ensure correct permissions for postgres user

            # Initialize the database cluster as the postgres user
            # Using a specific locale like C.UTF-8 is often recommended for compatibility.
            if sudo -iu postgres bash -c "initdb --locale=C.UTF-8 -E UTF8 -D \"$PG_DATA_DIR\""; then
                 echo "[02-official-packages] PostgreSQL database cluster initialized successfully in '$PG_DATA_DIR'."
                 PG_INIT_SUCCESS=true
            else
                 echo "[02-official-packages] Error: Failed to initialize PostgreSQL database cluster. Service will not be started."
                 echo "[02-official-packages] Check logs for details (e.g., journalctl -u postgresql.service) and permissions on $PG_DATA_DIR."
                 PG_INIT_SUCCESS=false
            fi
        else
            echo "[02-official-packages] PostgreSQL data directory '$PG_DATA_DIR' already exists. Assuming it's correctly initialized. Skipping initdb."
            # Ensure ownership and permissions are correct even if directory exists
            run_cmd "chown -R postgres:postgres \"$PG_DATA_DIR\""
            run_cmd "chmod -R 700 \"$PG_DATA_DIR\""
            PG_INIT_SUCCESS=true # Assume existing directory is okay
        fi
    fi

    # Attempt to start the service only if initdb was successful or data directory was already present
    if [[ "$PG_INIT_SUCCESS" == true ]]; then
        echo "[02-official-packages] Attempting to start PostgreSQL service..."
        run_cmd "systemctl start postgresql.service"
        
        if [[ "$DRY_RUN" == false ]]; then
            sleep 3 # Give the service a moment to start up
            if systemctl is-active --quiet postgresql.service; then
                echo "[02-official-packages] PostgreSQL service started successfully."
            else
                echo "[02-official-packages] Error: PostgreSQL service FAILED to start after initialization/check."
                echo "[02-official-packages] Please check logs for details:"
                echo "[02-official-packages]   sudo systemctl status postgresql.service"
                echo "[02-official-packages]   sudo journalctl -xeu postgresql.service"
            fi
        else
             echo "DRY-RUN ➜ Would check 'systemctl is-active --quiet postgresql.service' after attempting start."
        fi
    fi
else
    echo "[02-official-packages] PostgreSQL not in package list or not installed. Skipping PostgreSQL configuration."
fi

echo "[02-official-packages] Package installation and basic service configuration complete."

