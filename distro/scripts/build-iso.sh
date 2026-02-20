#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build"
ISO_WORK="$ROOT/workdir/iso"
GRUB_CFG="$ROOT/distro/iso/grub/grub.cfg"

mkdir -p "$ISO_WORK/boot/grub" "$BUILD"
cp "$GRUB_CFG" "$ISO_WORK/boot/grub/grub.cfg"

if [[ ! -f "$BUILD/kernel/bzImage" ]]; then
  echo "[iso] Missing kernel artifact: $BUILD/kernel/bzImage"
  exit 1
fi
if [[ ! -f "$BUILD/rootfs.squashfs" ]]; then
  echo "[iso] Missing rootfs artifact: $BUILD/rootfs.squashfs"
  exit 1
fi

cp "$BUILD/kernel/bzImage" "$ISO_WORK/boot/vmlinuz"
# placeholder initrd for now (replace with generated initramfs in next phase)
cp "$BUILD/rootfs.squashfs" "$ISO_WORK/boot/initrd.img"

xorriso -as mkisofs \
  -R -J -V BLUEPRINTOS \
  -b boot/grub/i386-pc/eltorito.img \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -o "$BUILD/blueprintos-dev.iso" "$ISO_WORK" || {
    echo "[iso] GRUB BIOS image missing; install grub-pc-bin and generate stage files in next iteration"
    exit 1
  }

echo "[iso] Done -> $BUILD/blueprintos-dev.iso"
