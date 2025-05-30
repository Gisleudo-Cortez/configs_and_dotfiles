#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script should run as the normal user.
# It's typically invoked by run-all.sh using "sudo -u \$SUDO_USER"
# If run directly, it should be as the target user.
if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[11-deploy-dotfiles] Error: This script is intended to be run as a normal user, not as root."
    echo "[11-deploy-dotfiles] If using run-all.sh, it should handle user delegation."
    echo "[11-deploy-dotfiles] If running manually, execute it without sudo: ./11-deploy-dotfiles.sh"
    exit 1
fi

CURRENT_USER_HOME="$HOME"
# In case this script is called via `sudo -u <user>`, $HOME should be correct.
# If for some reason it's not, this is a fallback, but primarily rely on $HOME.
if [[ -z "$CURRENT_USER_HOME" ]]; then
    echo "[11-deploy-dotfiles] Error: \$HOME directory not found for user $(whoami)."
    exit 1
fi

run_cmd_user() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        eval "$*"
    fi
}

# --- Configuration ---
# GitHub repository for dotfiles
GIT_REPO_URL="https://github.com/Gisleudo-Cortez/configs_and_dotfiles.git"
# Directory where the repo will be cloned/stored
# Using a subdirectory in Downloads as per original arch_postinstall.sh, adjust if needed.
DOTFILES_CLONE_DIR="$CURRENT_USER_HOME/Downloads/github/configs_and_dotfiles"
# Name of the directory inside the cloned repo that contains the stow packages.
# Assuming the stow packages (fish, nvim, etc.) are at the root of GIT_REPO_URL.
# If they are in a subdirectory like "dotfiles/" within the repo, set this:
# STOW_PACKAGES_SUBDIR="dotfiles" 
STOW_PACKAGES_SUBDIR="" # Empty if packages are at the root of the cloned repo

# Stow packages to deploy. These should be directory names within DOTFILES_CLONE_DIR/${STOW_PACKAGES_SUBDIR}
# Each directory name here corresponds to a "package" that stow will manage.
# The contents of each package directory should mirror the structure they'll have in $HOME.
# For example, if you have 'nvim/.config/nvim/...', stow will link $HOME/.config/nvim.
# For '.zshrc', the package 'zshrc' should contain a file named '.zshrc'.
STOW_PACKAGES_TO_DEPLOY=(
    "zshrc"  # Assuming this package contains the .zshrc file directly
    "fish"
    "hypr"
    "kitty"
    "nvim"
    "waybar"
)
# --- End Configuration ---

echo "[11-deploy-dotfiles] Deploying dotfiles for user $(whoami) to $CURRENT_USER_HOME"

# Ensure stow is installed
if ! command -v stow &> /dev/null; then
    echo "[11-deploy-dotfiles] Error: 'stow' command not found. Please install stow first."
    echo "[11-deploy-dotfiles] You can typically install it with 'sudo pacman -S stow'."
    if [[ "$DRY_RUN" == false ]]; then
        exit 1
    else
        echo "[11-deploy-dotfiles] DRY-RUN: Would have exited due to missing stow."
    fi
fi

# Create the parent directory for cloning if it doesn't exist
CLONE_PARENT_DIR=$(dirname "$DOTFILES_CLONE_DIR")
if [[ ! -d "$CLONE_PARENT_DIR" ]]; then
    echo "[11-deploy-dotfiles] Creating directory: $CLONE_PARENT_DIR"
    run_cmd_user "mkdir -p \"$CLONE_PARENT_DIR\""
fi

# Clone or update the dotfiles repository
if [[ -d "$DOTFILES_CLONE_DIR/.git" ]]; then
    echo "[11-deploy-dotfiles] Dotfiles repository already exists at $DOTFILES_CLONE_DIR. Updating..."
    run_cmd_user "git -C \"$DOTFILES_CLONE_DIR\" pull"
else
    echo "[11-deploy-dotfiles] Cloning dotfiles repository from $GIT_REPO_URL to $DOTFILES_CLONE_DIR..."
    run_cmd_user "git clone --depth=1 \"$GIT_REPO_URL\" \"$DOTFILES_CLONE_DIR\""
fi

# Directory from which stow commands will be run
STOW_RUN_DIR="$DOTFILES_CLONE_DIR"
if [[ -n "$STOW_PACKAGES_SUBDIR" ]]; then
    STOW_RUN_DIR="$DOTFILES_CLONE_DIR/$STOW_PACKAGES_SUBDIR"
fi

if [[ ! -d "$STOW_RUN_DIR" ]]; then
    echo "[11-deploy-dotfiles] Error: Stow packages directory not found: $STOW_RUN_DIR"
    echo "[11-deploy-dotfiles] Check your GIT_REPO_URL and STOW_PACKAGES_SUBDIR settings."
    if [[ "$DRY_RUN" == false ]]; then
        exit 1
    fi
fi

echo "[11-deploy-dotfiles] Changing to stow directory: $STOW_RUN_DIR"
if [[ "$DRY_RUN" == false ]]; then
    cd "$STOW_RUN_DIR" || { echo "Failed to cd into $STOW_RUN_DIR"; exit 1; }
fi


# Deploy specified packages using stow
echo "[11-deploy-dotfiles] Stowing packages to target directory: $CURRENT_USER_HOME"
for pkg in "${STOW_PACKAGES_TO_DEPLOY[@]}"; do
    if [[ -d "$STOW_RUN_DIR/$pkg" ]]; then # Check if package directory exists
        echo "[11-deploy-dotfiles] Stowing package: $pkg"
        # Stow command: -v (verbose), -S (symlink), -t (target directory)
        # The default action is to symlink (-S is often implied but good to be explicit)
        # We are running stow from within the $STOW_RUN_DIR, so paths are relative to it.
        # The target (-t) is $CURRENT_USER_HOME.
        run_cmd_user "stow -vSt \"$CURRENT_USER_HOME\" \"$pkg\""
    else
        echo "[11-deploy-dotfiles] Warning: Stow package directory '$pkg' not found in '$STOW_RUN_DIR'. Skipping."
    fi
done

# Return to original directory if changed (important for subsequent script runs if any)
if [[ "$DRY_RUN" == false ]]; then
    cd - > /dev/null # Go back to previous directory silently
fi

echo "[11-deploy-dotfiles] Dotfiles deployment process complete."
