#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=true

need_user

echo "[10-git-setup] • Applying Git configuration placeholders..."

# Set placeholder values
GIT_USER_NAME_PLACEHOLDER="Your Name"
GIT_USER_EMAIL_PLACEHOLDER="you@example.com"

run_cmd_user git config --global user.name "$GIT_USER_NAME_PLACEHOLDER"
run_cmd_user git config --global user.email "$GIT_USER_EMAIL_PLACEHOLDER"

echo "[10-git-setup] IMPORTANT: Git user.name and user.email have been set to placeholders."
echo "[10-git-setup] Please configure them manually with your actual details:"
echo "  git config --global user.name \"Your Real Name\""
echo "  git config --global user.email \"your.email@example.com\""

# GPG signing guidance
echo ""
echo "[10-git-setup] • Checking for GPG signing key..."
if command -v gpg >/dev/null 2>&1; then
    echo "[10-git-setup] To enable GPG signing after configuring your email:"
    echo "   1. Ensure you have a GPG key associated with your Git email."
    echo "   2. Find your GPG key ID: gpg --list-secret-keys --keyid-format long your.email@example.com"
    echo "   3. Set it in Git: git config --global user.signingkey YOUR_KEY_ID"
    echo "   4. Enable signing: git config --global commit.gpgsign true"
else
  echo "[10-git-setup] ⚠ GPG not installed – skipping GPG signing setup."
fi

echo "[10-git-setup] ✅ Git basic configuration guidance complete."
