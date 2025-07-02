#!/usr/bin/env bash
set -euo pipefail

# Source the helper functions
source "$(dirname "$0")/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

need_root

# Handle potential iptables conflict
if pacman -Qs iptables &>/dev/null && ! pacman -Qs iptables-nft &>/dev/null; then
    echo "[07-virt-setup] Legacy 'iptables' package found. Removing it to prevent conflict with 'iptables-nft'."
    run_cmd pacman -Rdd --noconfirm iptables
fi

# Install virtualization packages
PKGS=(
    qemu-desktop libvirt virt-manager virt-viewer
    dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft
)
echo "[07-virt-setup] Installing virtualization packages: ${PKGS[*]}"
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

# Enable libvirtd service
echo "[07-virt-setup] Enabling and starting libvirtd service..."
run_cmd systemctl enable --now libvirtd.service

# Add user to libvirt group
SUDO_USER_EFFECTIVE="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[07-virt-setup] Adding user '$SUDO_USER_EFFECTIVE' to 'libvirt' group..."
        run_cmd usermod -aG libvirt "$SUDO_USER_EFFECTIVE"
        echo "[07-virt-setup] User '$SUDO_USER_EFFECTIVE' added to 'libvirt' group. A re-login is required."
    else
        echo "[07-virt-setup] Warning: SUDO_USER '$SUDO_USER_EFFECTIVE' is not a valid user. Skipping add to libvirt group."
    fi
else
    echo "[07-virt-setup] Note: Could not determine a non-root user to add to the 'libvirt' group."
fi

echo "[07-virt-setup] Virtualization setup complete."
