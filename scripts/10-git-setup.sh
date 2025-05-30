#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# 10-git-setup.sh - Configure global Git identity & (optional) GPG commit-signing
#
# ‣ Run as **your normal user** ( NOT root).
# ‣ Supports `--dry-run` flag.
# ‣ ❶ Sets `user.name` and `user.email`.
# ‣ ❷ Enables GPG signing *if* a matching secret key already exists.
#     (No GPG key will be created by this script.)
#
#  NOTE: SSH-key management has been **removed** -- generate / copy your keys
#        manually (e.g.  `ssh-keygen -t ed25519 -C "you@example.com"` ).
# ──────────────────────────────────────────────────────────────────────────────
DRY_RUN=false
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=true

# Abort when executed as root (except in dry-run preview mode)
if [[ $EUID -eq 0 && $DRY_RUN == false ]]; then
  echo "[10-git-setup] ❌  Run this script as a regular user, not root."
  exit 1
fi

run()    { $DRY_RUN && echo "DRY-RUN ➜ $*" || eval "$*"; }
prompt() { $DRY_RUN && echo "$1 (skipped – dry-run)" || read -rp "$1" "$2"; }

echo "[10-git-setup] • Configuring global Git identity …"

# 1️⃣  Collect user.name / user.email
if [[ $DRY_RUN == true ]]; then
  GIT_NAME="<Your-Name>"
  GIT_EMAIL="you@example.com"
else
  prompt "Git user.name: " GIT_NAME
  prompt "Git user.email: " GIT_EMAIL
fi

run git config --global user.name  "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"

# 2️⃣  Optional – enable commit signing if GPG key already exists
if command -v gpg >/dev/null 2>&1; then
  GPG_KEY_ID=""
  if [[ $DRY_RUN == true ]]; then
    GPG_KEY_ID="<GPG-KEY-ID>"
  else
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_EMAIL" 2>/dev/null \
                  | awk '/^sec/{if(match($0,/[0-9A-F]{16}/,m)){print m[0];exit}}')
  fi

  if [[ -n $GPG_KEY_ID ]]; then
    run git config --global user.signingkey "$GPG_KEY_ID"
    run git config --global commit.gpgSign true
    echo "[10-git-setup] ✓ Enabled GPG commit-signing with key $GPG_KEY_ID"
  else
    echo "[10-git-setup] ⧗ No matching secret GPG key found – skipping signing setup."
  fi
else
  echo "[10-git-setup] ⚠ GPG not installed – skipping signing setup."
fi

echo "[10-git-setup] ✅ Git configuration complete."
