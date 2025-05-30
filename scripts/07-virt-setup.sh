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
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        # Ensure the command and its arguments are passed correctly
        # If the first argument is a command with spaces, eval might be needed
        # but for pacman and systemctl, this should be fine.
        "$@"
    fi
}
run_cmd_eval() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN ➜ $*"
    else
        echo "EXECUTING ➜ $*"
        eval "$*" 
    fi
}


echo "[07-virt-setup] Preparing for virtualization setup..."

# Handle potential iptables conflict before installing main packages
# If legacy iptables is installed, and we intend to install iptables-nft,
# remove the legacy one first to avoid interactive prompts with --noconfirm.
if pacman -Qs iptables &>/dev/null && ! pacman -Qs iptables-nft &>/dev/null; then
    echo "[07-virt-setup] Legacy 'iptables' package found. Attempting to remove it to prevent conflict with 'iptables-nft'."
    run_cmd_eval "pacman -Rdd --noconfirm iptables" # -Rdd to ignore dependencies, as iptables-nft will provide
                                             # Use with caution, but appropriate here as iptables-nft is a replacement.
                                             # A safer alternative if issues arise: pacman -R --noconfirm iptables
                                             # but that might fail if something strictly depends on the old package name.
fi


# Install virtualization packages: QEMU, libvirt, virt-manager, networking tools
# Specify a qemu provider, e.g., qemu-desktop for a common set of features, or qemu-full.
# qemu-base might be too minimal for virt-manager.
PKGS=(
    qemu-desktop libvirt virt-manager virt-viewer   # core virtualization and management with qemu-desktop provider
    dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables-nft  # networking for VMs
)
echo "[07-virt-setup] Installing virtualization packages: ${PKGS[*]}"
run_cmd_eval "pacman -S --needed --noconfirm ${PKGS[*]}"


# Enable libvirtd (this also starts virtlogd via socket activation)
echo "[07-virt-setup] Enabling and starting libvirtd service..."
run_cmd_eval "systemctl enable --now libvirtd.service"

# Add the user to libvirt group for managing VMs without root (if run via sudo)
SUDO_USER_EFFECTIVE="${SUDO_USER:-}"
if [[ -z "$SUDO_USER_EFFECTIVE" && "$EUID" -eq 0 ]]; then
    SUDO_USER_EFFECTIVE=$(logname 2>/dev/null)
fi

if [[ -n "$SUDO_USER_EFFECTIVE" && "$SUDO_USER_EFFECTIVE" != "root" ]]; then
    if id -u "$SUDO_USER_EFFECTIVE" &>/dev/null; then
        echo "[07-virt-setup] Adding user '$SUDO_USER_EFFECTIVE' to 'libvirt' group..."
        run_cmd_eval "usermod -aG libvirt \"$SUDO_USER_EFFECTIVE\""
        echo "[07-virt-setup] User '$SUDO_USER_EFFECTIVE' added to 'libvirt' group. A re-login is required for this to take effect."
    else
        echo "[07-virt-setup] Warning: SUDO_USER '$SUDO_USER_EFFECTIVE' does not seem to be a valid user. Skipping add to libvirt group."
    fi
else
    echo "[07-virt-setup] Note: Could not determine a non-root user (SUDO_USER not set or is root)."
    echo "[07-virt-setup] If you have a regular user, add them to the 'libvirt' group manually (e.g., 'sudo usermod -aG libvirt your_username') to use virt-manager without root."
fi

echo "[07-virt-setup] Virtualization packages installed and libvirtd service enabled."

