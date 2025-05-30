#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script is intended to run as a normal user.
# AUR helpers (paru, yay) will use sudo internally when needed.
# makepkg should be run as a normal user; installation of the built package will use sudo.
if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[02b-aur-packages] Error: This script should be run as a regular user, not as root."
    echo "[02b-aur-packages] run-all.sh should delegate this script to run as the non-root user."
    exit 1
fi

run_cmd_user_eval() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        eval "$*"
    fi
}

echo "[02b-aur-packages] Preparing to install AUR packages..."

# Define the list of AUR packages to install here
# Add more packages to this array as needed.
PACKAGES_TO_INSTALL=(
    "find-the-command"
    # "another-aur-package"
    # "yet-another-one"
)

OVERALL_SUCCESS=true

for PACKAGE_NAME in "${PACKAGES_TO_INSTALL[@]}"; do
    echo ""
    echo "[02b-aur-packages] --- Processing AUR package: $PACKAGE_NAME ---"
    INSTALLED_SUCCESSFULLY=false

    # Attempt 1: Use paru (if installed by 02-official-packages.sh)
    if command -v paru &> /dev/null; then
        echo "[02b-aur-packages] Found 'paru'. Attempting to install '$PACKAGE_NAME'..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ paru -S --noconfirm --needed $PACKAGE_NAME"
            INSTALLED_SUCCESSFULLY=true # Assume success for dry run for this package
        elif paru -S --noconfirm --needed "$PACKAGE_NAME"; then
            echo "[02b-aur-packages] '$PACKAGE_NAME' installed successfully using paru."
            INSTALLED_SUCCESSFULLY=true
        else
            echo "[02b-aur-packages] Failed to install '$PACKAGE_NAME' using paru. Trying next method."
        fi
    fi

    # Attempt 2: Use yay (if paru failed or not found, and yay is installed)
    if [[ "$INSTALLED_SUCCESSFULLY" == false ]] && command -v yay &> /dev/null; then
        echo "[02b-aur-packages] Found 'yay'. Attempting to install '$PACKAGE_NAME'..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ yay -S --noconfirm --needed $PACKAGE_NAME"
            INSTALLED_SUCCESSFULLY=true # Assume success for dry run for this package
        elif yay -S --noconfirm --needed "$PACKAGE_NAME"; then
            echo "[02b-aur-packages] '$PACKAGE_NAME' installed successfully using yay."
            INSTALLED_SUCCESSFULLY=true
        else
            echo "[02b-aur-packages] Failed to install '$PACKAGE_NAME' using yay. Trying manual method."
        fi
    fi

    # Attempt 3: Manual git clone and makepkg -si (if helpers failed or not found)
    if [[ "$INSTALLED_SUCCESSFULLY" == false ]]; then
        echo "[02b-aur-packages] AUR helper not found or failed for '$PACKAGE_NAME'. Attempting manual installation..."
        
        if ! command -v git &> /dev/null || ! command -v makepkg &> /dev/null; then
            echo "[02b-aur-packages] Error: 'git' and/or 'makepkg' (from base-devel group) are required for manual AUR installation. Please install them. Skipping '$PACKAGE_NAME'."
            OVERALL_SUCCESS=false
            continue # Skip to the next package in the loop
        fi

        TEMP_BUILD_DIR_PKG="" # Specific temp dir for this package
        if [[ "$DRY_RUN" == false ]]; then
            TEMP_BUILD_DIR_PKG=$(mktemp -d -t "aurbuild_${PACKAGE_NAME}_XXX")
            echo "[02b-aur-packages] Created temporary build directory for '$PACKAGE_NAME': $TEMP_BUILD_DIR_PKG"
            # Ensure cleanup on exit - this trap will re-register for each loop, but that's okay.
            # A more robust approach might be to collect all temp dirs and clean at the very end.
            # For simplicity, we'll clean up this specific package's temp dir.
            # However, a single trap at the script start for a parent temp dir might be cleaner if many packages are built.
            # For now, this is fine.
        fi

        echo "[02b-aur-packages] Cloning AUR repository for '$PACKAGE_NAME'..."
        # Use a specific clone path for the current package
        CLONE_PATH="$TEMP_BUILD_DIR_PKG/$PACKAGE_NAME"
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ git clone https://aur.archlinux.org/$PACKAGE_NAME.git \"some_temp_dir/$PACKAGE_NAME\""
        else
            # Ensure the parent of CLONE_PATH exists (TEMP_BUILD_DIR_PKG)
            mkdir -p "$TEMP_BUILD_DIR_PKG" 
            if ! git clone "https://aur.archlinux.org/$PACKAGE_NAME.git" "$CLONE_PATH"; then
                echo "[02b-aur-packages] Error: Failed to clone AUR repository for '$PACKAGE_NAME'. Skipping."
                rm -rf "$TEMP_BUILD_DIR_PKG" # Clean up this package's temp dir
                OVERALL_SUCCESS=false
                continue # Skip to the next package
            fi
        fi
        
        if [[ "$DRY_RUN" == false ]]; then
          pushd "$CLONE_PATH" > /dev/null
        fi

        echo "[02b-aur-packages] Building and installing '$PACKAGE_NAME' using makepkg -si --noconfirm..."
        if [[ "$DRY_RUN" == true ]]; then
            echo "DRY-RUN (user: $(whoami)) ➜ cd to_build_dir && makepkg -si --noconfirm"
            INSTALLED_SUCCESSFULLY=true # Assume success for dry run for this package
        elif makepkg -si --noconfirm; then
            echo "[02b-aur-packages] '$PACKAGE_NAME' built and installed successfully via makepkg."
            INSTALLED_SUCCESSFULLY=true
        else
            echo "[02b-aur-packages] Failed to build/install '$PACKAGE_NAME' using makepkg."
        fi
        
        if [[ "$DRY_RUN" == false ]]; then
          popd > /dev/null
          echo "[02b-aur-packages] Cleaning up temporary build directory for '$PACKAGE_NAME': $TEMP_BUILD_DIR_PKG"
          rm -rf "$TEMP_BUILD_DIR_PKG"
        fi
    fi

    if [[ "$INSTALLED_SUCCESSFULLY" == true ]]; then
        echo "[02b-aur-packages] '$PACKAGE_NAME' setup process finished."
    else
        echo "[02b-aur-packages] FAILED to install '$PACKAGE_NAME' using any available method."
        OVERALL_SUCCESS=false # Mark overall script as having at least one failure
    fi
done

echo ""
if [[ "$OVERALL_SUCCESS" == true ]]; then
    echo "[02b-aur-packages] All specified AUR packages processed successfully."
else
    echo "[02b-aur-packages] One or more AUR packages FAILED to install."
    exit 1 # Indicate failure to run-all.sh
fi

echo "[02b-aur-packages] AUR package processing complete."
