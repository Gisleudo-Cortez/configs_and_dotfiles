#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# This script should run as the normal user.
if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[11-deploy-dotfiles] Error: This script is intended to be run as a normal user, not as root."
    echo "[11-deploy-dotfiles] If using run-all.sh, it should handle user delegation."
    echo "[11-deploy-dotfiles] If running manually, execute it without sudo: ./11-deploy-dotfiles.sh"
    exit 1
fi

CURRENT_USER_HOME="$HOME"
if [[ -z "$CURRENT_USER_HOME" ]]; then
    echo "[11-deploy-dotfiles] Error: \$HOME directory not found for user $(whoami)."
    exit 1
fi

run_cmd_user() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        eval "$*" # Using eval to correctly handle commands with arguments and quotes
    fi
}

# --- Configuration ---
GIT_REPO_URL="https://github.com/Gisleudo-Cortez/configs_and_dotfiles.git"
DOTFILES_CLONE_DIR="$CURRENT_USER_HOME/Downloads/github/configs_and_dotfiles"
STOW_PACKAGES_SUBDIR="" # Empty if packages are at the root of the cloned repo

STOW_PACKAGES_TO_DEPLOY=(
    "zshrc"
    "fish"
    "hypr"
    "kitty"
    "nvim"
    "waybar"
)
# --- End Configuration ---

echo "[11-deploy-dotfiles] Deploying dotfiles for user $(whoami) to $CURRENT_USER_HOME"

if ! command -v stow &> /dev/null; then
    echo "[11-deploy-dotfiles] Error: 'stow' command not found. Please install stow first."
    if [[ "$DRY_RUN" == false ]]; then
        exit 1
    fi
fi

CLONE_PARENT_DIR=$(dirname "$DOTFILES_CLONE_DIR")
if [[ ! -d "$CLONE_PARENT_DIR" ]]; then
    echo "[11-deploy-dotfiles] Creating directory: $CLONE_PARENT_DIR"
    run_cmd_user "mkdir -p \"$CLONE_PARENT_DIR\""
fi

if [[ -d "$DOTFILES_CLONE_DIR/.git" ]]; then
    echo "[11-deploy-dotfiles] Dotfiles repository already exists at $DOTFILES_CLONE_DIR. Updating..."
    run_cmd_user "git -C \"$DOTFILES_CLONE_DIR\" pull"
else
    echo "[11-deploy-dotfiles] Cloning dotfiles repository from $GIT_REPO_URL to $DOTFILES_CLONE_DIR..."
    run_cmd_user "git clone --depth=1 \"$GIT_REPO_URL\" \"$DOTFILES_CLONE_DIR\""
fi

STOW_RUN_DIR="$DOTFILES_CLONE_DIR"
if [[ -n "$STOW_PACKAGES_SUBDIR" ]]; then
    STOW_RUN_DIR="$DOTFILES_CLONE_DIR/$STOW_PACKAGES_SUBDIR"
fi

if [[ ! -d "$STOW_RUN_DIR" ]]; then
    echo "[11-deploy-dotfiles] Error: Stow packages directory not found: $STOW_RUN_DIR"
    if [[ "$DRY_RUN" == false ]]; then
        exit 1
    fi
fi

echo "[11-deploy-dotfiles] Changing to stow directory: $STOW_RUN_DIR"
# Store the original PWD to return to it later
ORIGINAL_PWD=$(pwd)
if [[ "$DRY_RUN" == false ]]; then
    cd "$STOW_RUN_DIR" || { echo "[11-deploy-dotfiles] Error: Failed to cd into $STOW_RUN_DIR"; exit 1; }
fi

# Pre-handle known conflicting files before stowing
# This specifically targets regular files that would block stow.
# Symlinks will be handled by `stow -R`.
echo "[11-deploy-dotfiles] Checking for conflicting regular files..."
for pkg_name in "${STOW_PACKAGES_TO_DEPLOY[@]}"; do
    SOURCE_PKG_DIR="$STOW_RUN_DIR/$pkg_name"
    if [[ ! -d "$SOURCE_PKG_DIR" ]]; then
        echo "[11-deploy-dotfiles] Warning: Source package directory '$SOURCE_PKG_DIR' for package '$pkg_name' not found. Skipping conflict check for this package."
        continue
    fi

    echo "[11-deploy-dotfiles] Checking conflicts for package: $pkg_name"
    # Find all files within the current source package directory
    # Use -print0 and read -d $'\0' to handle filenames with spaces, newlines, etc.
    find "$SOURCE_PKG_DIR" -type f -print0 | while IFS= read -r -d $'\0' source_file_path; do
        # Determine the path of the file relative to the root of THIS package directory.
        # This relative path is what stow will try to create/link in the target directory ($HOME).
        # Example: if source_file_path is /stow_dir/pkg_name/.config/foo/bar.txt
        # then path_in_stow_package will be .config/foo/bar.txt
        path_in_stow_package="${source_file_path#"$SOURCE_PKG_DIR/"}"
        
        TARGET_FILE="$CURRENT_USER_HOME/$path_in_stow_package"

        # Only proceed if the target is an actual regular file (not a symlink, not a directory)
        # The -f check also implicitly checks if the parent directory of TARGET_FILE exists.
        # If the parent directory doesn't exist, -f "$TARGET_FILE" will be false.
        if [[ -f "$TARGET_FILE" && ! -L "$TARGET_FILE" ]]; then
            BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"
            echo "[11-deploy-dotfiles] Conflicting regular file found: '$TARGET_FILE'"
            echo "[11-deploy-dotfiles] (This target corresponds to '$path_in_stow_package' in stow package '$pkg_name')"
            echo "[11-deploy-dotfiles] Backing it up to '$BACKUP_FILE' and removing original."
            run_cmd_user "mv \"$TARGET_FILE\" \"$BACKUP_FILE\""
        fi
    done
done

echo "[11-deploy-dotfiles] Stowing packages to target directory: $CURRENT_USER_HOME"
for pkg in "${STOW_PACKAGES_TO_DEPLOY[@]}"; do
    if [[ -d "$STOW_RUN_DIR/$pkg" ]]; then # Check if package directory exists in the stow source
        echo "[11-deploy-dotfiles] Stowing package: $pkg"
        # Use -R (restow) to handle existing symlinks from this package gracefully.
        # -v (verbose), -t (target directory)
        # Stow command is run from $STOW_RUN_DIR
        run_cmd_user "stow -Rvt \"$CURRENT_USER_HOME\" \"$pkg\""
    else
        echo "[11-deploy-dotfiles] Warning: Stow package directory '$pkg' not found in '$STOW_RUN_DIR'. Skipping."
    fi
done

# Return to original directory
if [[ "$DRY_RUN" == false ]]; then
    cd "$ORIGINAL_PWD" || echo "[11-deploy-dotfiles] Warning: Failed to cd back to original directory '$ORIGINAL_PWD'."
fi

echo "[11-deploy-dotfiles] Dotfiles deployment process complete."

