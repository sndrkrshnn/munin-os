#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/workdir/rootfs"
BUILD="$ROOT/build"
OVERLAY="$ROOT/distro/rootfs/overlay"
PKGS_FILE="$ROOT/distro/rootfs/packages/base.txt"

# Use sudo only when needed/available
if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "[rootfs] ERROR: need root privileges or sudo installed"
    exit 1
  fi
fi

$SUDO mkdir -p "$WORK" "$BUILD/live"

if [[ ! -f "$WORK/.debootstrap_done" ]]; then
  $SUDO debootstrap --arch=amd64 bookworm "$WORK" http://deb.debian.org/debian
  $SUDO touch "$WORK/.debootstrap_done"
fi

PKGS=$(tr '\n' ' ' < "$PKGS_FILE")
$SUDO chroot "$WORK" bash -lc "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGS"

# overlay + firstboot/services
$SUDO rsync -a "$OVERLAY/" "$WORK/"

# ship UI assets into OS image
$SUDO mkdir -p "$WORK/opt/muninos/ui"
$SUDO rsync -a "$ROOT/munin-ui/" "$WORK/opt/muninos/ui/" || true

# ship compiled Munin binaries when available
if [[ -d "$ROOT/build/munin-bin" ]]; then
  $SUDO mkdir -p "$WORK/opt/muninos/bin"
  $SUDO rsync -a "$ROOT/build/munin-bin/" "$WORK/opt/muninos/bin/"
fi

# ensure executable scripts
$SUDO chmod +x \
  "$WORK/usr/local/bin/munin-firstboot" \
  "$WORK/usr/local/bin/munin-firstboot-wizard" \
  "$WORK/usr/local/bin/munin-core" \
  "$WORK/usr/local/bin/munin-sts" \
  "$WORK/usr/local/bin/munin-ui" || true

# enable systemd units in image root
$SUDO chroot "$WORK" bash -lc 'systemctl enable munin-firstboot.service munin-core.service munin-sts.service munin-ui.service || true'

# regenerate initramfs for installed kernel
$SUDO chroot "$WORK" bash -lc 'KVER=$(ls /lib/modules | sort -V | tail -n1); update-initramfs -c -k "$KVER"'

# export live boot assets from rootfs kernel by default
KERNEL_PATH=$($SUDO chroot "$WORK" bash -lc 'ls /boot/vmlinuz-* | sort -V | tail -n1')
INITRD_PATH=$($SUDO chroot "$WORK" bash -lc 'ls /boot/initrd.img-* | sort -V | tail -n1')

$SUDO cp "$WORK$KERNEL_PATH" "$BUILD/live/vmlinuz"
$SUDO cp "$WORK$INITRD_PATH" "$BUILD/live/initrd.img"

# if custom kernel exists, export and prefer later in ISO stage
if [[ -f "$BUILD/kernel/bzImage" ]]; then
  $SUDO cp "$BUILD/kernel/bzImage" "$BUILD/live/vmlinuz-custom"
fi

# live rootfs
$SUDO mksquashfs "$WORK" "$BUILD/live/filesystem.squashfs" -noappend -comp xz

echo "[rootfs] Done"
echo "  - $BUILD/live/vmlinuz"
echo "  - $BUILD/live/initrd.img"
echo "  - $BUILD/live/filesystem.squashfs"
if [[ -f "$BUILD/live/vmlinuz-custom" ]]; then
  echo "  - $BUILD/live/vmlinuz-custom (custom kernel available)"
fi
