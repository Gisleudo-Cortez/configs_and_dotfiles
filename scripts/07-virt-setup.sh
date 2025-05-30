#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Needs root for installation and service configuration
if [[ "$EUID" -ne 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "[07-virt-setup] Warning: Not running as root, but continuing in dry-run mode."
    else 
        echo "[07-virt-setup] Error: This script must be run as root."
        exit 1
    fi
fi

run_cmd() {
    echo "[07-virt-setup] Running: $*"
    if [[ "$DRY_RUN" != true ]]; then
        "$@"
    fi
}

# Install virtualization packages: QEMU, libvirt, virt-manager, networking tools
PKGS=(
    qemu libvirt virt-manager virt-viewer   # core virtualization and management
    dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft  # networking for VMs
)
run_cmd pacman -S --needed --noconfirm "${PKGS[@]}"

# Enable libvirtd (this also starts virtlogd via socket activation)
run_cmd systemctl enable --now libvirtd.service

# Add the user to libvirt group for managing VMs without root (if run via sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    run_cmd usermod -aG libvirt "${SUDO_USER}"
    echo "[07-virt-setup] Added user '${SUDO_USER}' to 'libvirt' group (effective on next login)."
else
    echo "[07-virt-setup] (No SUDO_USER detected; if you have a regular user, add them to 'libvirt' group to use VMs in virt-manager without root.)"
fi

echo "[07-virt-setup] Virtualization packages installed and libvirtd service enabled."
