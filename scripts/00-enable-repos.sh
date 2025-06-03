#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=true

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        eval "$*" # eval is appropriate here as commands are passed as single strings
    fi
}

need_root() {
  if [[ $EUID -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[00-enable-repos] Warning: Not running as root, but continuing in dry-run mode." >&2
    else
        echo "[00-enable-repos] Error: This script must be run as root (use sudo)." >&2
        exit 1
    fi
  fi
}
need_root

echo "[00-enable-repos] Enabling required pacman repositories…"

## 1️⃣  Ensure [extra] is enabled (present by default; just verify)
if ! grep -q -E "^\s*\[extra\]" /etc/pacman.conf; then
  echo "[00-enable-repos] ERROR: [extra] repo block missing or commented out – check your /etc/pacman.conf" >&2
  if [[ "$DRY_RUN" == false ]]; then
    exit 1
  fi
fi
echo "[00-enable-repos] [extra] repository confirmed."

## 2️⃣  Enable [multilib] (uncomment block if still commented)
if grep -q -E "^\s*#\s*\[multilib\]" /etc/pacman.conf; then
  echo "[00-enable-repos] Enabling multilib repo by uncommenting..."
  run_cmd "sed -i -E 's/^\s*#\s*(\[multilib\])/\1/;s/^\s*#\s*(Include\s*=\s*\/etc\/pacman.d\/mirrorlist)/\1/' /etc/pacman.conf"
elif ! grep -q -E "^\s*\[multilib\]" /etc/pacman.conf; then
  echo "[00-enable-repos] Warning: [multilib] repository block not found. You may need to add it manually if required." >&2
else
  echo "[00-enable-repos] [multilib] repository already enabled or configured."
fi


## 3️⃣  Add chaotic-aur (keyring + mirrorlist + repo block)
CHAOTIC_KEYRING_PKG="chaotic-keyring"
CHAOTIC_MIRRORLIST_PKG="chaotic-mirrorlist"
CHAOTIC_REPO_NAME="chaotic-aur"

if grep -q -E "^\s*\[${CHAOTIC_REPO_NAME}\]" /etc/pacman.conf; then
    echo "[00-enable-repos] [chaotic-aur] repository already appears to be configured in /etc/pacman.conf."
else
    echo "[00-enable-repos] Setting up [chaotic-aur] repository..."
    KEYS_TO_IMPORT=("FBA220DFC880C036" "3056513887B78AEB")
    KEYSERVER="hkps://keyserver.ubuntu.com"

    for KEY_ID in "${KEYS_TO_IMPORT[@]}"; do
        if pacman-key -l "$KEY_ID" &>/dev/null; then
            echo "[00-enable-repos] GPG Key $KEY_ID already imported."
        else
            echo "[00-enable-repos] Importing GPG Key $KEY_ID from $KEYSERVER..."
            run_cmd "pacman-key --recv-key \"$KEY_ID\" --keyserver \"$KEYSERVER\""
            echo "[00-enable-repos] Locally signing GPG Key $KEY_ID..."
            run_cmd "pacman-key --lsign-key \"$KEY_ID\""
        fi
    done

    KEYRING_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
    MIRRORLIST_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"

    if pacman -Qs "$CHAOTIC_KEYRING_PKG" &>/dev/null && pacman -Qs "$CHAOTIC_MIRRORLIST_PKG" &>/dev/null; then
        echo "[00-enable-repos] $CHAOTIC_KEYRING_PKG and $CHAOTIC_MIRRORLIST_PKG already installed."
    else
        echo "[00-enable-repos] Installing $CHAOTIC_KEYRING_PKG and $CHAOTIC_MIRRORLIST_PKG..."
        run_cmd "pacman -U --needed --noconfirm \"$KEYRING_URL\" \"$MIRRORLIST_URL\""
    fi

    echo "[00-enable-repos] Adding [chaotic-aur] repo to /etc/pacman.conf..."
    TEMP_REPO_CONF=$(mktemp)
    # Using printf for potentially better handling of special characters if any were in the string
    printf "\n[%s]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" "$CHAOTIC_REPO_NAME" > "$TEMP_REPO_CONF"
    
    run_cmd "cat \"$TEMP_REPO_CONF\" >> /etc/pacman.conf"
    rm "$TEMP_REPO_CONF"
    echo "[00-enable-repos] [chaotic-aur] repository added."
fi

## 4️⃣  Refresh package databases (synchronize only)
echo "[00-enable-repos] Refreshing pacman databases (pacman -Syy)..."
run_cmd "pacman -Syy"

echo "[00-enable-repos] Repository setup complete."
