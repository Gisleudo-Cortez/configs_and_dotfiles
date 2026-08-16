#!/usr/bin/env bash
# 14-deploy-mullvad-tailscale.sh
#
# Deploys the Mullvad split-tunnel exclusion for Tailscale:
#   - /etc/nftables/tailscale-exclude.rules  (the nftables rules)
#   - /etc/systemd/system/mullvad-tailscale-exclusion.service  (boot loader)
#
# The package lives in the dotfiles repo at mullvad-tailscale/ and targets
# /etc (not $HOME), so it needs its own root-target stow step — it is NOT
# part of 11-deploy-dotfiles.sh.
#
# Usage:
#   sudo ./14-deploy-mullvad-tailscale.sh            # deploy + enable
#   sudo ./14-deploy-mullvad-tailscale.sh --dry-run  # preview only
#   sudo ./14-deploy-mullvad-tailscale.sh --verify   # check deployed state
#
# Requires: stow, nft, systemd. Must run as root (targets /etc).

set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
VERIFY_ONLY=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi
if [[ "${1:-}" == "--verify" ]]; then
    VERIFY_ONLY=true
fi

need_root

STOW_PACKAGE="mullvad-tailscale"
RULES_FILE="/etc/nftables/tailscale-exclude.rules"
UNIT_FILE="/etc/systemd/system/mullvad-tailscale-exclusion.service"

main() {
    if ! command -v stow &>/dev/null; then
        echo "[14-deploy-mullvad-tailscale] Error: 'stow' command not found. Please install it first."
        exit 1
    fi

    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local dotfiles_root
    dotfiles_root=$(git -C "$script_dir" rev-parse --show-toplevel)

    if [[ -z "$dotfiles_root" ]]; then
        echo "[14-deploy-mullvad-tailscale] Error: Could not find the git repository root."
        exit 1
    fi

    cd "$dotfiles_root"

    if [[ "$VERIFY_ONLY" == true ]]; then
        echo "[14-deploy-mullvad-tailscale] Verifying deployment..."
        [[ -f "$RULES_FILE" ]] && echo "  OK: $RULES_FILE" || echo "  MISSING: $RULES_FILE"
        [[ -f "$UNIT_FILE" ]] && echo "  OK: $UNIT_FILE" || echo "  MISSING: $UNIT_FILE"
        systemctl is-enabled mullvad-tailscale-exclusion.service 2>/dev/null || echo "  NOT ENABLED: mullvad-tailscale-exclusion.service"
        systemctl is-active mullvad-tailscale-exclusion.service 2>/dev/null || echo "  NOT ACTIVE: mullvad-tailscale-exclusion.service"
        return 0
    fi

    echo "[14-deploy-mullvad-tailscale] Deploying from $dotfiles_root"

    # Stow the package with target /etc (root-target stow)
    run_cmd stow -Svt /etc "$STOW_PACKAGE"

    # Pre-flight: validate the rules file syntax without loading
    run_cmd nft -c -f "$RULES_FILE"

    # Enable the service (starts it immediately via daemon-reload + start)
    run_cmd systemctl daemon-reload
    run_cmd systemctl enable --now mullvad-tailscale-exclusion.service

    echo "[14-deploy-mullvad-tailscale] Deployment complete."
    echo "  Verify: sudo nft list table inet excludeTraffic"
    echo "  Test:   ping -c 3 <tailscale-peer-ip>"
    echo "  Rollback: sudo systemctl disable --now mullvad-tailscale-exclusion.service && sudo nft delete table inet excludeTraffic"
}

main
