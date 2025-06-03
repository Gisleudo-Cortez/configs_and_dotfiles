#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=true

if [[ $EUID -eq 0 && $DRY_RUN == false ]]; then
  echo "[10-git-setup] ❌ Run this script as a regular user, not root."
  exit 1
fi

run_git_config() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN (user: $(whoami)) ➜ git config --global $*"
    else
        echo "EXECUTING (user: $(whoami)) ➜ git config --global $*"
        git config --global "$@"
    fi
}

echo "[10-git-setup] • Applying Git configuration placeholders..."

# Set placeholder values or leave empty
GIT_USER_NAME_PLACEHOLDER="Your Name"
GIT_USER_EMAIL_PLACEHOLDER="you@example.com"

run_git_config user.name "$GIT_USER_NAME_PLACEHOLDER"
run_git_config user.email "$GIT_USER_EMAIL_PLACEHOLDER"

echo "[10-git-setup] IMPORTANT: Git user.name and user.email have been set to placeholders."
echo "[10-git-setup] Please configure them manually with your actual details:"
echo "  git config --global user.name \"Your Real Name\""
echo "  git config --global user.email \"your.email@example.com\""

# Optional – enable commit signing if GPG key already exists for the placeholder email
# Or guide the user
echo ""
echo "[10-git-setup] • Checking for GPG signing key..."
if command -v gpg >/dev/null 2>&1; then
  GPG_KEY_ID=""
  if [[ "$DRY_RUN" == true ]]; then
    GPG_KEY_ID="<GPG-KEY-ID-DRY-RUN>"
    echo "DRY-RUN (user: $(whoami)) ➜ Would attempt to find GPG key for $GIT_USER_EMAIL_PLACEHOLDER"
  else
    # Try to find a key for the placeholder email (user will change this email later)
    # This is unlikely to find a useful key unless the user already uses the placeholder.
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$GIT_USER_EMAIL_PLACEHOLDER" 2>/dev/null \
                  | awk '/^sec/{if(match($0,/[0-9A-F]{16}/,m)){print m[0];exit}}')
  fi

  if [[ -n "$GPG_KEY_ID" ]]; then
    run_git_config user.signingkey "$GPG_KEY_ID"
    run_git_config commit.gpgsign true
    echo "[10-git-setup] ✓ Enabled GPG commit-signing with placeholder key $GPG_KEY_ID for $GIT_USER_EMAIL_PLACEHOLDER."
    echo "[10-git-setup]   You will likely need to update this after setting your correct email and GPG key:"
    echo "  gpg --list-secret-keys --keyid-format long your.email@example.com  (to find your key ID)"
    echo "  git config --global user.signingkey YOUR_KEY_ID"
  else
    echo "[10-git-setup] ⧗ No GPG key found for the placeholder email ($GIT_USER_EMAIL_PLACEHOLDER)."
    echo "[10-git-setup]   To enable GPG signing after configuring your email:"
    echo "   1. Ensure you have a GPG key associated with your Git email."
    echo "   2. Find your GPG key ID: gpg --list-secret-keys --keyid-format long your.email@example.com"
    echo "   3. Set it in Git: git config --global user.signingkey YOUR_KEY_ID"
    echo "   4. Enable signing: git config --global commit.gpgsign true"
  fi
else
  echo "[10-git-setup] ⚠ GPG not installed – skipping GPG signing setup."
fi

echo "[10-git-setup] ✅ Git basic configuration guidance complete."
