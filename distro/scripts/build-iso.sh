#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build"
ISO_WORK="$ROOT/workdir/iso"
GRUB_CFG="$ROOT/distro/iso/grub/grub.cfg"

mkdir -p "$ISO_WORK/boot/grub" "$ISO_WORK/live" "$BUILD"
cp "$GRUB_CFG" "$ISO_WORK/boot/grub/grub.cfg"

for f in vmlinuz initrd.img filesystem.squashfs; do
  if [[ ! -f "$BUILD/live/$f" ]]; then
    echo "[iso] Missing artifact: $BUILD/live/$f"
    exit 1
  fi
  cp "$BUILD/live/$f" "$ISO_WORK/live/$f"
done

if command -v grub-mkrescue >/dev/null 2>&1; then
  grub-mkrescue -o "$BUILD/blueprintos-dev.iso" "$ISO_WORK"
else
  echo "[iso] grub-mkrescue not found. Install grub-pc-bin + grub-efi-amd64-bin + xorriso"
  exit 1
fi

echo "[iso] Done -> $BUILD/blueprintos-dev.iso"
