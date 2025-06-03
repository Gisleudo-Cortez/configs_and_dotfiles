#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    echo "[11-deploy-dotfiles] Error: This script is intended to be run as a normal user, not as root." >&2
    echo "[11-deploy-dotfiles] If using run-all.sh, it should handle user delegation." >&2
    echo "[11-deploy-dotfiles] If running manually, execute it without sudo: ./11-deploy-dotfiles.sh" >&2
    exit 1
fi

CURRENT_USER_HOME="$HOME"
if [[ -z "$CURRENT_USER_HOME" || ! -d "$CURRENT_USER_HOME" ]]; then # Added check for directory existence
    echo "[11-deploy-dotfiles] Error: \$HOME directory ('$CURRENT_USER_HOME') not found or not a directory for user $(whoami)." >&2
    exit 1
fi

run_cmd_user() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ $*"
        eval "$*" # eval is appropriate here for commands like git clone with URLs or stow with complex args
    fi
}

GIT_REPO_URL="https://github.com/Gisleudo-Cortez/configs_and_dotfiles.git"
DOTFILES_CLONE_DIR="$CURRENT_USER_HOME/Downloads/github/configs_and_dotfiles"
STOW_PACKAGES_SUBDIR="" 

STOW_PACKAGES_TO_DEPLOY=(
    "zshrc"
    "fish"
    "hypr"
    "kitty"
    "nvim"
    "waybar"
    "rofi"
    "starship"
    "starship.toml"
    "starship_cat.toml"
)

echo "[11-deploy-dotfiles] Deploying dotfiles for user $(whoami) to $CURRENT_USER_HOME"

if ! command -v stow &> /dev/null; then
    echo "[11-deploy-dotfiles] Error: 'stow' command not found. Please install stow first." >&2
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
    echo "[11-deploy-dotfiles] Error: Stow packages directory not found: $STOW_RUN_DIR" >&2
    if [[ "$DRY_RUN" == false ]]; then
        exit 1
    fi
fi

echo "[11-deploy-dotfiles] Changing to stow directory: $STOW_RUN_DIR"
ORIGINAL_PWD=$(pwd)
if [[ "$DRY_RUN" == false ]]; then
    cd "$STOW_RUN_DIR" || { echo "[11-deploy-dotfiles] Error: Failed to cd into $STOW_RUN_DIR" >&2; exit 1; }
fi

echo "[11-deploy-dotfiles] Checking for conflicting regular files..."
for pkg_name in "${STOW_PACKAGES_TO_DEPLOY[@]}"; do
    SOURCE_PKG_DIR="$STOW_RUN_DIR/$pkg_name"
    if [[ ! -d "$SOURCE_PKG_DIR" ]]; then
        echo "[11-deploy-dotfiles] Warning: Source package directory '$SOURCE_PKG_DIR' for package '$pkg_name' not found. Skipping conflict check for this package." >&2
        continue
    fi

    echo "[11-deploy-dotfiles] Checking conflicts for package: $pkg_name"
    find "$SOURCE_PKG_DIR" -type f -print0 | while IFS= read -r -d $'\0' source_file_path; do
        path_in_stow_package="${source_file_path#"$SOURCE_PKG_DIR/"}"
        TARGET_FILE="$CURRENT_USER_HOME/$path_in_stow_package"

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
    if [[ -d "$STOW_RUN_DIR/$pkg" ]]; then
        echo "[11-deploy-dotfiles] Stowing package: $pkg"
        run_cmd_user "stow -Rvt \"$CURRENT_USER_HOME\" \"$pkg\""
    else
        echo "[11-deploy-dotfiles] Warning: Stow package directory '$pkg' not found in '$STOW_RUN_DIR'. Skipping." >&2
    fi
done

if [[ "$DRY_RUN" == false ]]; then
    cd "$ORIGINAL_PWD" || echo "[11-deploy-dotfiles] Warning: Failed to cd back to original directory '$ORIGINAL_PWD'." >&2
fi

echo "[11-deploy-dotfiles] Dotfiles deployment process complete."
