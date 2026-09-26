#!/usr/bin/env bash
# 14-deploy-mullvad-tailscale.sh
#
# Deploys the Mullvad split-tunnel exclusion for Tailscale AND the local-LAN
# bypass ip rule:
#   - /etc/nftables/tailscale-exclude.rules                              (nft)
#   - /etc/systemd/system/mullvad-tailscale-exclusion.service            (boot loader)
#   - /usr/local/lib/mullvad-tailscale/apply-lan-bypass.sh               (ip rule)
#
# Two stow packages: `mullvad-tailscale` (→ /etc) and `mullvad-tailscale-helper`
# (→ /usr/local). GNU Stow can only target one root per package invocation,
# so we run stow twice. Both packages live in the dotfiles repo.
#
# Usage:
#   sudo ./14-deploy-mullvad-tailscale.sh            # deploy + enable + reload
#   sudo ./14-deploy-mullvad-tailscale.sh --dry-run  # simulate stow + validate rules
#   sudo ./14-deploy-mullvad-tailscale.sh --verify   # check deployed state (exit 1 on failure)
#
# Requires: stow, nft, systemd. Must run as root (targets /etc and /usr/local).

set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
VERIFY_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verify)  VERIFY_ONLY=true ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--dry-run] [--verify]" >&2
            exit 2
            ;;
    esac
done

need_root

STOW_PACKAGE_ETC="mullvad-tailscale"
STOW_PACKAGE_USR="mullvad-tailscale-helper"
RULES_FILE="/etc/nftables/tailscale-exclude.rules"
UNIT_FILE="/etc/systemd/system/mullvad-tailscale-exclusion.service"
HELPER_FILE="/usr/local/lib/mullvad-tailscale/apply-lan-bypass.sh"
SERVICE="mullvad-tailscale-exclusion.service"

main() {
    local script_dir dotfiles_root
    script_dir=$(cd "$(dirname "$0")" && pwd)
    dotfiles_root=$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)

    if [[ -z "$dotfiles_root" ]]; then
        echo "[14-deploy-mullvad-tailscale] Error: Could not find the git repository root."
        exit 1
    fi

    cd "$dotfiles_root"

    if [[ "$VERIFY_ONLY" == true ]]; then
        verify_deployment
        return
    fi

    if ! command -v stow &>/dev/null; then
        echo "[14-deploy-mullvad-tailscale] Error: 'stow' command not found. Please install it first."
        exit 1
    fi
    if ! command -v nft &>/dev/null; then
        echo "[14-deploy-mullvad-tailscale] Error: 'nft' command not found. Please install nftables first."
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        dry_run_deploy
        return
    fi

    deploy
}

verify_deployment() {
    local failures=0
    echo "[14-deploy-mullvad-tailscale] Verifying deployment..."

    if [[ -f "$RULES_FILE" ]]; then
        echo "  OK: $RULES_FILE"
    else
        echo "  MISSING: $RULES_FILE"
        failures=$((failures + 1))
    fi

    if [[ -f "$UNIT_FILE" ]]; then
        echo "  OK: $UNIT_FILE"
    else
        echo "  MISSING: $UNIT_FILE"
        failures=$((failures + 1))
    fi

    if [[ -f "$HELPER_FILE" ]]; then
        echo "  OK: $HELPER_FILE"
    else
        echo "  MISSING: $HELPER_FILE"
        failures=$((failures + 1))
    fi

    if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
        echo "  OK: $SERVICE enabled"
    else
        echo "  NOT ENABLED: $SERVICE"
        failures=$((failures + 1))
    fi

    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        echo "  OK: $SERVICE active"
    else
        echo "  NOT ACTIVE: $SERVICE"
        failures=$((failures + 1))
    fi

    if ! command -v nft &>/dev/null; then
        echo "  ERROR: 'nft' command not found — cannot verify ruleset"
        failures=$((failures + 1))
    elif nft list table inet excludeTraffic >/dev/null 2>&1; then
        echo "  OK: nftables table inet excludeTraffic loaded"
    else
        echo "  MISSING: nftables table inet excludeTraffic"
        failures=$((failures + 1))
    fi

    if ip rule list 2>/dev/null | grep -Fq 'from 192.168.2.0/24 to 192.168.2.0/24 lookup main'; then
        echo "  OK: ip rule 2500 (from-scoped LAN bypass) installed"
    else
        echo "  MISSING: ip rule 2500 (from-scoped LAN bypass) — service start probably failed"
        failures=$((failures + 1))
    fi

    if [[ "$failures" -eq 0 ]]; then
        echo "All checks passed."
    else
        echo "$failures check(s) failed."
        exit 1
    fi
}

dry_run_deploy() {
    echo "[14-deploy-mullvad-tailscale] Dry run — simulating deployment from $dotfiles_root"

    # Real stow simulation (read-only) — both packages, both roots
    stow --simulate --verbose --target=/etc "$STOW_PACKAGE_ETC"
    stow --simulate --verbose --target=/usr/local "$STOW_PACKAGE_USR"

    # Validate the source rules file without loading
    nft -c -f "mullvad-tailscale/nftables/tailscale-exclude.rules"
    echo "  OK: rules file syntax valid"

    # Validate the helper script syntax (bash -n is read-only)
    bash -n "mullvad-tailscale-helper/lib/mullvad-tailscale/apply-lan-bypass.sh"
    echo "  OK: helper script syntax valid"

    echo "[14-deploy-mullvad-tailscale] Dry run complete — no changes made."
}

deploy() {
    echo "[14-deploy-mullvad-tailscale] Deploying from $dotfiles_root"

    # 1. Validate the source rules file BEFORE touching /etc
    nft -c -f "mullvad-tailscale/nftables/tailscale-exclude.rules"
    echo "  OK: source rules file syntax valid"
    bash -n "mullvad-tailscale-helper/lib/mullvad-tailscale/apply-lan-bypass.sh"
    echo "  OK: helper script syntax valid"

    # 2. Stow both packages (two roots: /etc and /usr/local)
    run_cmd stow -Svt /etc "$STOW_PACKAGE_ETC"
    run_cmd stow -Svt /usr/local "$STOW_PACKAGE_USR"

    # 3. Pre-flight: validate the deployed rules file without loading
    run_cmd nft -c -f "$RULES_FILE"

    # 4. Enable + reload-or-restart. A plain `enable --now` does NOT restart an
    #    already-active service, so updated rules would never reach the kernel.
    run_cmd systemctl daemon-reload
    run_cmd systemctl enable "$SERVICE"
    run_cmd systemctl reload-or-restart "$SERVICE"

    # 5. Verify the table actually loaded
    if nft list table inet excludeTraffic >/dev/null 2>&1; then
        echo "  OK: table inet excludeTraffic loaded"
    else
        echo "  ERROR: table not loaded after service start — check 'systemctl status $SERVICE'"
        exit 1
    fi

    echo "[14-deploy-mullvad-tailscale] Deployment complete."
    echo "  Verify: sudo nft list table inet excludeTraffic"
    echo "  Verify: sudo ip rule list | grep 'from 192.168.2.0/24 to 192.168.2.0/24'"
    echo "  Test:   ping -c 3 <tailscale-peer-ip>"
    echo "  Rollback: sudo systemctl disable --now $SERVICE; sudo nft delete table inet excludeTraffic 2>/dev/null || true"
}

main
