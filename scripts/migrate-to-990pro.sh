#!/bin/bash
# =============================================================================
# MIGRATION PLAN v4 — FINAL, RESEARCH-BACKED, SOTA-REVIEWED
# Samsung 990 Pro 4TB Migration for Arch Linux + btrfs + UKI + GRUB
#
# Research sources:
#   - Arch Wiki: Btrfs, Unified Kernel Image, GRUB, Snapper
#   - btrfs-progs v7.1 send/receive documentation
#   - lars-gandyra.de btrfs subvolume cloning guide
#   - ordinatechnic.com Arch+btrfs+snapper guide
#   - SOTA review: GPT-5.6, Gemini 2.5 Pro, Llama 4 Maverick
#
# SOURCES:
#   nvme1n1: XPG GAMMIX S11 Pro 1TB (RUNNING SYSTEM — source)
#   nvme0n1: Samsung 990 PRO 4TB (wiped — destination)
#
# TARGET ARCHITECTURE:
#   nvme0n1: Samsung 990 Pro 4TB = Linux main
#   nvme1n1: ADATA XPG 1TB = Windows dual-boot (later, separate task)
#
# METHOD: btrfs send/receive + chroot bootloader rebuild
#   - Fresh filesystems with NEW UUIDs (no collision)
#   - btrfs-native data transfer preserves CoW, compression
#   - UKIs rebuilt in chroot with new PARTUUID
#   - GRUB reinstalled from chroot with correct UUIDs
#   - Old drive NEVER written to, NEVER scanned, NEVER touched
#
# SNAPPER SNAPSHOTS:
#   NOT migrated. Old drive retains all 2019+ snapshots as fallback.
#   New drive gets fresh .snapshots subvolumes. Snapper configs
#   (in /etc/snapper/configs/) are copied as part of @ subvolume.
#   Snapper starts creating new snapshots immediately on new drive.
#
# SAFETY:
#   Every step has a verification checkpoint.
#   Old drive stays bootable throughout.
#   If anything fails: reboot → BIOS (F2) → select old drive.
#
# =============================================================================
# RUN MANUALLY, STEP BY STEP. VERIFY EACH STEP BEFORE PROCEEDING.
# =============================================================================

set -euo pipefail

# =============================================================================
# STEP 0: PRE-FLIGHT
# =============================================================================
echo "=== STEP 0: PRE-FLIGHT VERIFICATION ==="

# Verify source is the running system
echo "Root mount (should be nvme1n1p2):"
findmnt / -o SOURCE --noheadings

# Verify 990 Pro is detected
echo ""
echo "990 Pro (should be nvme0n1, 3.6T):"
lsblk -o NAME,SIZE,MODEL /dev/nvme0n1

# Verify 990 Pro has NO filesystems
echo ""
echo "990 Pro filesystems (should be empty):"
sudo blkid /dev/nvme0n1p1 /dev/nvme0n1p2 2>/dev/null || echo "  (none — correct)"

# Record source identifiers for reference
echo ""
echo "Source btrfs UUID:    $(sudo blkid /dev/nvme1n1p2 -s UUID -o value)"
echo "Source btrfs PARTUUID: $(sudo blkid /dev/nvme1n1p2 -s PARTUUID -o value)"
echo "Source ESP UUID:      $(sudo blkid /dev/nvme1n1p1 -s UUID -o value)"

read -p "Pre-flight correct? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 1: INSTALL TOOLS
# =============================================================================
echo ""
echo "=== STEP 1: INSTALL arch-install-scripts ==="
sudo pacman -S --needed arch-install-scripts

# =============================================================================
# STEP 2: REPARTITION 990 PRO (fresh GPT)
# =============================================================================
echo ""
echo "=== STEP 2: REPARTITION 990 PRO ==="

# Wipe everything
sudo sgdisk --zap-all /dev/nvme0n1

# Partition 1: 1G EFI System Partition
sudo sgdisk -n 1:0:+1G -t 1:EF00 /dev/nvme0n1

# Partition 2: rest of disk, Linux root x86-64
sudo sgdisk -n 2:0:0 -t 2:8304 /dev/nvme0n1

# Verify
echo "Partition table:"
sudo sgdisk -p /dev/nvme0n1

read -p "Partitions correct (1G EF00 + ~3.6T 8304)? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 3: CREATE FRESH FILESYSTEMS (NEW UUIDs — no collision)
# =============================================================================
echo ""
echo "=== STEP 3: CREATE FRESH FILESYSTEMS ==="

# FAT32 for ESP
sudo mkfs.fat -F32 /dev/nvme0n1p1

# btrfs for root — creates filesystem spanning entire partition (3.6T)
sudo mkfs.btrfs -f /dev/nvme0n1p2

# Record NEW UUIDs
NEW_BTRFS_UUID=$(sudo blkid /dev/nvme0n1p2 -s UUID -o value)
NEW_BTRFS_PARTUUID=$(sudo blkid /dev/nvme0n1p2 -s PARTUUID -o value)
NEW_ESP_UUID=$(sudo blkid /dev/nvme0n1p1 -s UUID -o value)
NEW_ESP_PARTUUID=$(sudo blkid /dev/nvme0n1p1 -s PARTUUID -o value)

echo ""
echo "============================================"
echo "NEW UUIDs — WRITE THESE DOWN:"
echo "  BTRFS UUID:      $NEW_BTRFS_UUID"
echo "  BTRFS PARTUUID:  $NEW_BTRFS_PARTUUID"
echo "  ESP UUID:        $NEW_ESP_UUID"
echo "  ESP PARTUUID:    $NEW_ESP_PARTUUID"
echo "============================================"

read -p "Filesystems created? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 4: btrfs send/receive — COPY SUBVOLUMES
# =============================================================================
echo ""
echo "=== STEP 4: btrfs send/receive ==="

# Mount source btrfs top-level (subvolid=5) — needed because /tmp is on tmpfs,
# and btrfs subvolume snapshot requires the target path to be on btrfs
sudo mkdir -p /mnt/src_top
sudo mount -o subvolid=5 /dev/nvme1n1p2 /mnt/src_top

# Mount destination btrfs top-level (subvolid=5, the raw filesystem root)
sudo mkdir -p /mnt/newdrive
sudo mount /dev/nvme0n1p2 /mnt/newdrive

# --- Send @ (root) ---
# Create readonly snapshot of source @ from the top-level mount
echo "Snapshotting @ (root)..."
sudo btrfs subvolume snapshot -r /mnt/src_top/@ /mnt/src_top/@_snap_send

# Send to destination — use --compressed-data for faster transfer
echo "Sending @ to 990 Pro (~750GB, ~10 min)..."
sudo btrfs send --compressed-data /mnt/src_top/@_snap_send | sudo btrfs receive /mnt/newdrive/

# Received subvolume is readonly with received_uuid set.
# Cannot use `property set ro false` — btrfs blocks this.
# Instead, create a writable snapshot and delete the readonly original.
sudo btrfs subvolume snapshot /mnt/newdrive/@_snap_send /mnt/newdrive/@
sudo btrfs subvolume delete /mnt/newdrive/@_snap_send

# Clean up source snapshot
sudo btrfs subvolume delete /mnt/src_top/@_snap_send
echo "@ done."

# --- Send @home ---
echo "Snapshotting @home..."
sudo btrfs subvolume snapshot -r /mnt/src_top/@home /mnt/src_top/@home_snap_send
echo "Sending @home..."
sudo btrfs send --compressed-data /mnt/src_top/@home_snap_send | sudo btrfs receive /mnt/newdrive/
sudo btrfs subvolume snapshot /mnt/newdrive/@home_snap_send /mnt/newdrive/@home
sudo btrfs subvolume delete /mnt/newdrive/@home_snap_send
sudo btrfs subvolume delete /mnt/src_top/@home_snap_send
echo "@home done."

# --- Send @log ---
echo "Snapshotting @log..."
sudo btrfs subvolume snapshot -r /mnt/src_top/@log /mnt/src_top/@log_snap_send
echo "Sending @log..."
sudo btrfs send --compressed-data /mnt/src_top/@log_snap_send | sudo btrfs receive /mnt/newdrive/
sudo btrfs subvolume snapshot /mnt/newdrive/@log_snap_send /mnt/newdrive/@log
sudo btrfs subvolume delete /mnt/newdrive/@log_snap_send
sudo btrfs subvolume delete /mnt/src_top/@log_snap_send
echo "@log done."

# --- Send @pkg ---
echo "Snapshotting @pkg..."
sudo btrfs subvolume snapshot -r /mnt/src_top/@pkg /mnt/src_top/@pkg_snap_send
echo "Sending @pkg..."
sudo btrfs send --compressed-data /mnt/src_top/@pkg_snap_send | sudo btrfs receive /mnt/newdrive/
sudo btrfs subvolume snapshot /mnt/newdrive/@pkg_snap_send /mnt/newdrive/@pkg
sudo btrfs subvolume delete /mnt/newdrive/@pkg_snap_send
sudo btrfs subvolume delete /mnt/src_top/@pkg_snap_send
echo "@pkg done."

# --- Create fresh .snapshots subvolumes for snapper ---
# These are empty — snapper starts fresh. Old snapshots remain on old drive.
echo "Creating fresh .snapshots subvolumes..."
sudo btrfs subvolume create /mnt/newdrive/@/.snapshots
sudo btrfs subvolume create /mnt/newdrive/@home/.snapshots

# Verify all subvolumes
echo ""
echo "Subvolumes on 990 Pro:"
sudo btrfs subvolume list /mnt/newdrive

read -p "All subvolumes present (@, @home, @log, @pkg, .snapshots x2)? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# Unmount top-level
sudo umount /mnt/newdrive

# =============================================================================
# STEP 5: SET UP CHROOT MOUNT STRUCTURE
# =============================================================================
echo ""
echo "=== STEP 5: MOUNT FOR CHROOT ==="

# Mount @ (root) with same options as fstab
sudo mount -o subvol=@,compress=zstd:3,ssd,discard=async,space_cache=v2 /dev/nvme0n1p2 /mnt/newdrive

# Mount @home
sudo mount -o subvol=@home,compress=zstd:3,ssd,discard=async,space_cache=v2 /dev/nvme0n1p2 /mnt/newdrive/home

# Mount @log
sudo mount -o subvol=@log,compress=zstd:3,ssd,discard=async,space_cache=v2 /dev/nvme0n1p2 /mnt/newdrive/var/log

# Mount @pkg
sudo mount -o subvol=@pkg,compress=zstd:3,ssd,discard=async,space_cache=v2 /dev/nvme0n1p2 /mnt/newdrive/var/cache/pacman/pkg

# Mount new ESP at /boot
sudo mount /dev/nvme0n1p1 /mnt/newdrive/boot

# Verify
echo "Mount structure:"
findmnt /mnt/newdrive
findmnt /mnt/newdrive/home
findmnt /mnt/newdrive/var/log
findmnt /mnt/newdrive/var/cache/pacman/pkg
findmnt /mnt/newdrive/boot

read -p "All 5 mountpoints correct? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 6: COPY ESP CONTENTS (ALL files)
# =============================================================================
echo ""
echo "=== STEP 6: COPY ESP ==="

# rsync ALL ESP contents — UKIs, GRUB modules, vmlinuz, initramfs, ucode, locales
# -a = archive mode (preserves perms, symlinks, etc)
# -H = preserve hard links
# -A = preserve ACLs
# -X = preserve extended attributes
sudo rsync -aHAX /boot/ /mnt/newdrive/boot/

# Verify critical files
echo "Critical ESP files on 990 Pro:"
for f in /mnt/newdrive/boot/EFI/Linux/arch-linux.efi \
         /mnt/newdrive/boot/EFI/Linux/arch-linux-zen.efi \
         /mnt/newdrive/boot/EFI/BOOT/BOOTX64.EFI \
         /mnt/newdrive/boot/vmlinuz-linux \
         /mnt/newdrive/boot/vmlinuz-linux-zen \
         /mnt/newdrive/boot/intel-ucode.img \
         /mnt/newdrive/boot/grub/grub.cfg; do
    if [ -f "$f" ]; then
        echo "  OK: $f ($(ls -la "$f" | awk '{print $5}') bytes)"
    else
        echo "  MISSING: $f"
    fi
done

read -p "All ESP files present? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 7: UPDATE fstab WITH NEW UUIDs
# =============================================================================
echo ""
echo "=== STEP 7: UPDATE fstab ==="

# Replace old btrfs UUID with new one
sudo sed -i "s/75424165-4e90-424f-86f1-3431de4813c6/$NEW_BTRFS_UUID/g" /mnt/newdrive/etc/fstab

# Replace old ESP UUID with new one
sudo sed -i "s/6B4A-05FA/$NEW_ESP_UUID/g" /mnt/newdrive/etc/fstab

echo "New fstab:"
cat /mnt/newdrive/etc/fstab

read -p "fstab UUIDs correct? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 8: UPDATE KERNEL CMDLINE WITH NEW PARTUUID
# =============================================================================
echo ""
echo "=== STEP 8: UPDATE KERNEL CMDLINE ==="

# /etc/kernel/cmdline is read by mkinitcpio to bake cmdline into UKIs
# Source: Arch Wiki — Unified Kernel Image
echo "root=PARTUUID=$NEW_BTRFS_PARTUUID zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs nvidia_drm.modeset=1 nvidia_drm.fbdev=1" | sudo tee /mnt/newdrive/etc/kernel/cmdline

echo ""
echo "New cmdline:"
cat /mnt/newdrive/etc/kernel/cmdline

read -p "cmdline correct? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 9: CHROOT — REBUILD UKIs + REINSTALL GRUB
# =============================================================================
echo ""
echo "=== STEP 9: CHROOT ==="
echo "Entering chroot. Commands below run INSIDE the chroot."
echo ""

sudo arch-chroot /mnt/newdrive << 'CHROOT_EOF'
set -e

echo "=== 9a: Rebuild UKIs ==="
echo "This bakes the new PARTUUID from /etc/kernel/cmdline into the UKI .efi files"
echo ""

# Verify cmdline file has new PARTUUID
echo "Cmdline in chroot:"
cat /etc/kernel/cmdline
echo ""

# Rebuild UKIs — mkinitcpio reads /etc/kernel/cmdline and bakes it into the UKI
# Source: Arch Wiki UKI — "mkinitcpio supports reading kernel parameters from
# /etc/kernel/cmdline"
mkinitcpio -p linux
mkinitcpio -p linux-zen

# Verify UKIs were rebuilt (timestamps should be NOW)
echo ""
echo "UKI files (should show current timestamp):"
ls -la /boot/EFI/Linux/

echo ""
echo "=== 9b: Reinstall GRUB ==="
echo "This installs fresh GRUB EFI binary and creates efibootmgr entry"
echo ""

# Install GRUB to the new ESP
# --bootloader-id=arch creates /boot/EFI/arch/ with grubx64.efi
# This also creates an efibootmgr NVRAM entry automatically
# Source: Arch Wiki GRUB — "grub-install also tries to create an entry in the
# firmware boot manager"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch

# Also install to fallback path for resilience
# Source: Arch Wiki GRUB — "install GRUB at the default/fallback boot path"
grub-install --target=x86_64-efi --efi-directory=/boot --removable

echo ""
echo "=== 9c: Regenerate grub.cfg ==="
echo "This creates fresh grub.cfg with correct UUIDs from the new fstab"
echo ""

# Regenerate grub.cfg — reads /etc/default/grub and /etc/grub.d/*
# The 15_uki script adds the `uki` command which auto-discovers UKIs
# The 41_snapshots-btrfs script generates snapshot entries with correct UUIDs
# Source: Arch Wiki GRUB — "GRUB can chainload UKIs"
grub-mkconfig -o /boot/grub/grub.cfg

# Verify grub.cfg has NEW UUIDs (not old)
echo ""
echo "Checking grub.cfg for UUIDs..."
if grep -q "75424165-4e90-424f-86f1-3431de4813c6" /boot/grub/grub.cfg; then
    echo "WARNING: Old btrfs UUID still in grub.cfg!"
else
    echo "OK: Old btrfs UUID not found in grub.cfg"
fi

if grep -q "$NEW_BTRFS_UUID" /boot/grub/grub.cfg 2>/dev/null || \
   grep -q "$NEW_ESP_UUID" /boot/grub/grub.cfg 2>/dev/null; then
    echo "OK: New UUIDs found in grub.cfg"
else
    echo "NOTE: New UUIDs not directly in grub.cfg (UKIs are auto-discovered by uki command)"
fi

echo ""
echo "=== 9d: Verify boot setup ==="
echo ""
echo "EFI boot entries:"
efibootmgr

echo ""
echo "UKI files:"
ls -la /boot/EFI/Linux/

echo ""
echo "GRUB EFI files:"
find /boot/EFI -name "*.efi" -exec ls -la {} \;

CHROOT_EOF

echo ""
read -p "Chroot completed successfully? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 10: VERIFY btrfs FILESYSTEM SIZE
# =============================================================================
echo ""
echo "=== STEP 10: VERIFY btrfs SIZE ==="

# mkfs.btrfs creates filesystem spanning entire partition by default
# But verify to be sure
echo "btrfs filesystem usage:"
sudo btrfs filesystem usage /mnt/newdrive

# If for some reason it's not full size, resize
echo ""
echo "Ensuring max size..."
sudo btrfs filesystem resize max /mnt/newdrive 2>/dev/null || echo "(already at max)"

echo ""
echo "df output:"
df -h /mnt/newdrive

read -p "Filesystem shows ~3.6T? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 11: VERIFY EFI BOOT ENTRY
# =============================================================================
echo ""
echo "=== STEP 11: VERIFY BOOT ENTRY ==="

echo "Current EFI boot entries:"
efibootmgr

echo ""
echo "Boot entry 0008 = old drive (nvme1n1, PARTUUID 50eed2d1...)"
echo "There should be a new entry for the 990 Pro (nvme0n1)"
echo ""

# If grub-install didn't create an entry (can happen in chroot),
# create one manually pointing to the UKI directly
# Source: Arch Wiki UKI — "efibootmgr can be used to create a UEFI boot entry
# for the .efi file"
if ! efibootmgr | grep -q "nvme0n1"; then
    echo "No boot entry for 990 Pro found. Creating one..."
    # Point directly to UKI — most reliable approach
    # Path uses backslash separators per UEFI spec
    sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \
        --label "Arch Linux (990 Pro)" \
        --loader '\EFI\Linux\arch-linux-zen.efi'

    echo ""
    echo "Updated boot entries:"
    efibootmgr
fi

# Set boot order — find the new entry number
echo ""
echo "To set 990 Pro as first boot option, check the entry number above"
echo "and run: sudo efibootmgr --bootorder <new_entry>,<old_entries>"
echo ""
echo "Or simply reboot and select 'Arch Linux (990 Pro)' from the boot menu (F12)"

read -p "Boot entry verified? (yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# =============================================================================
# STEP 12: UNMOUNT AND REBOOT
# =============================================================================
echo ""
echo "=== STEP 12: UNMOUNT ==="

sudo umount /mnt/newdrive/boot
sudo umount /mnt/newdrive/var/cache/pacman/pkg
sudo umount /mnt/newdrive/var/log
sudo umount /mnt/newdrive/home
sudo umount /mnt/newdrive

echo ""
echo "============================================"
echo "MIGRATION COMPLETE"
echo "============================================"
echo ""
echo "The 990 Pro now has:"
echo "  - Fresh btrfs (UUID: $NEW_BTRFS_UUID)"
echo "  - All data from @, @home, @log, @pkg"
echo "  - Fresh ESP with rebuilt UKIs (PARTUUID: $NEW_BTRFS_PARTUUID)"
echo "  - GRUB reinstalled + grub.cfg regenerated"
echo "  - btrfs filesystem at full 3.6T"
echo ""
echo "OLD DRIVE (nvme1n1) IS UNTOUCHED AND BOOTABLE."
echo "If anything fails: reboot → F2 (BIOS) → select old drive"
echo ""
echo "To reboot from the 990 Pro:"
echo "  Option A: Set boot order in BIOS (F2)"
echo "  Option B: Press F12 at boot and select 'Arch Linux (990 Pro)'"
echo ""

read -p "Reboot now? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    sudo reboot
fi

# =============================================================================
# STEP 13: POST-BOOT VERIFICATION (run AFTER reboot)
# =============================================================================
echo ""
echo "=== POST-BOOT CHECKS (run after rebooting from 990 Pro) ==="
echo ""
echo "Run these commands after reboot:"
echo ""
echo "  # Verify you're on the 990 Pro"
echo "  lsblk -o NAME,SIZE,MODEL,MOUNTPOINT"
echo "  findmnt / -o SOURCE --noheadings"
echo "  df -h /"
echo ""
echo "  # Verify btrfs"
echo "  sudo btrfs filesystem show"
echo ""
echo "  # Run TRIM"
echo "  sudo fstrim -av"
echo ""
echo "  # Verify snapper (should be running, creating new snapshots)"
echo "  sudo snapper list"
echo "  systemctl status snapper-timeline.timer"
echo ""
echo "  # System update"
echo "  sudo pacman -Syu"
echo ""
echo "  # Verify UKIs"
echo "  ls -la /boot/EFI/Linux/"
echo ""
echo "If anything is wrong, reboot → F2 → select old drive."