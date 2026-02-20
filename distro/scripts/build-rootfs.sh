#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/workdir/rootfs"
BUILD="$ROOT/build"
OVERLAY="$ROOT/distro/rootfs/overlay"
PKGS_FILE="$ROOT/distro/rootfs/packages/base.txt"

sudo mkdir -p "$WORK" "$BUILD"

if [[ ! -f "$WORK/.debootstrap_done" ]]; then
  sudo debootstrap --arch=amd64 bookworm "$WORK" http://deb.debian.org/debian
  sudo touch "$WORK/.debootstrap_done"
fi

# install package list
PKGS=$(tr '\n' ' ' < "$PKGS_FILE")
sudo chroot "$WORK" bash -lc "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGS"

# apply overlay
sudo rsync -a "$OVERLAY/" "$WORK/"

# make firstboot executable
sudo chmod +x "$WORK/usr/local/bin/blueprint-firstboot" || true

# squashfs artifact
sudo mksquashfs "$WORK" "$BUILD/rootfs.squashfs" -noappend -comp xz

echo "[rootfs] Done -> $BUILD/rootfs.squashfs"
