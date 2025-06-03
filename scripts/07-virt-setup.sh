#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[07-virt-setup] Warning: Not running as root, but continuing in dry-run mode." >&2
    else
        echo "[07-virt-setup] Error: This script must be run as root." >&2
        exit 1
    fi
fi

# For commands passed as a single string needing eval
run_cmd_eval() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        eval "$*" 
    fi
}

# For commands passed with arguments already separated
run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        "$@"
    fi
}

echo "[07-virt-setup] Preparing for virtualization setup..."

if pacman -Qs iptables &>/dev/null && ! pacman -Qs iptables-nft &>/dev/null; then
    echo "[07-virt-setup] Legacy 'iptables' package found. Attempting to remove it to prevent conflict with 'iptables-nft'."
    run_cmd_eval "pacman -Rdd --noconfirm iptables" 
fi

PKGS=(
    qemu-desktop libvirt virt-manager virt-viewer
    dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft
)
echo "[07-virt-setup] Installing virtualization packages: ${PKGS[*]}"
# Using run_cmd with "$@" for pacman
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

echo "[07-virt-setup] Enabling and starting libvirtd service..."
run_cmd systemctl enable --now libvirtd.service

SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null)
fi

if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[07-virt-setup] Adding user '$SUDO_USER_EFFECTIVE' to 'libvirt' group..."
        run_cmd usermod -aG libvirt "$SUDO_USER_EFFECTIVE"
        echo "[07-virt-setup] User '$SUDO_USER_EFFECTIVE' added to 'libvirt' group. A re-login is required for this to take effect."
    else
        echo "[07-virt-setup] Warning: SUDO_USER '$SUDO_USER_EFFECTIVE' does not seem to be a valid user. Skipping add to libvirt group." >&2
    fi
else
    echo "[07-virt-setup] Note: Could not determine a non-root user (SUDO_USER not set or is root)."
    echo "[07-virt-setup] If you have a regular user, add them to the 'libvirt' group manually (e.g., 'sudo usermod -aG libvirt your_username') to use virt-manager without root."
fi

echo "[07-virt-setup] Virtualization packages installed and libvirtd service enabled."
