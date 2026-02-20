#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/workdir/rootfs"
BUILD="$ROOT/build"
OVERLAY="$ROOT/distro/rootfs/overlay"
PKGS_FILE="$ROOT/distro/rootfs/packages/base.txt"

sudo mkdir -p "$WORK" "$BUILD/live"

if [[ ! -f "$WORK/.debootstrap_done" ]]; then
  sudo debootstrap --arch=amd64 bookworm "$WORK" http://deb.debian.org/debian
  sudo touch "$WORK/.debootstrap_done"
fi

PKGS=$(tr '\n' ' ' < "$PKGS_FILE")
sudo chroot "$WORK" bash -lc "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGS"

# overlay + firstboot/services
sudo rsync -a "$OVERLAY/" "$WORK/"

# ship UI assets into OS image
sudo mkdir -p "$WORK/opt/muninos/ui"
sudo rsync -a "$ROOT/blueprint-ui/" "$WORK/opt/muninos/ui/" || true

# ensure executable scripts
sudo chmod +x \
  "$WORK/usr/local/bin/munin-firstboot" \
  "$WORK/usr/local/bin/munin-firstboot-wizard" \
  "$WORK/usr/local/bin/munin-core" \
  "$WORK/usr/local/bin/munin-sts" \
  "$WORK/usr/local/bin/munin-ui" || true

# enable systemd units in image root
sudo chroot "$WORK" bash -lc 'systemctl enable munin-firstboot.service munin-core.service munin-sts.service munin-ui.service || true'

# regenerate initramfs for installed kernel
sudo chroot "$WORK" bash -lc 'KVER=$(ls /lib/modules | sort -V | tail -n1); update-initramfs -c -k "$KVER"'

# export live boot assets from rootfs kernel by default
KERNEL_PATH=$(sudo chroot "$WORK" bash -lc 'ls /boot/vmlinuz-* | sort -V | tail -n1')
INITRD_PATH=$(sudo chroot "$WORK" bash -lc 'ls /boot/initrd.img-* | sort -V | tail -n1')

sudo cp "$WORK$KERNEL_PATH" "$BUILD/live/vmlinuz"
sudo cp "$WORK$INITRD_PATH" "$BUILD/live/initrd.img"

# if custom kernel exists, export and prefer later in ISO stage
if [[ -f "$BUILD/kernel/bzImage" ]]; then
  sudo cp "$BUILD/kernel/bzImage" "$BUILD/live/vmlinuz-custom"
fi

# live rootfs
sudo mksquashfs "$WORK" "$BUILD/live/filesystem.squashfs" -noappend -comp xz

echo "[rootfs] Done"
echo "  - $BUILD/live/vmlinuz"
echo "  - $BUILD/live/initrd.img"
echo "  - $BUILD/live/filesystem.squashfs"
if [[ -f "$BUILD/live/vmlinuz-custom" ]]; then
  echo "  - $BUILD/live/vmlinuz-custom (custom kernel available)"
fi
