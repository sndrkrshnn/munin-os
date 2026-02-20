#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build"
OVERLAY="$ROOT/distro/rootfs/overlay"
PKGS_FILE="$ROOT/distro/rootfs/packages/base.txt"

# Build architecture (amd64|arm64)
ARCH="${ARCH:-arm64}"
case "$ARCH" in
  amd64|arm64) ;;
  *) echo "[rootfs] ERROR: unsupported ARCH=$ARCH (use amd64 or arm64)"; exit 1 ;;
esac

# Default login user for generated images (override via env)
DEFAULT_USER="${DEFAULT_USER:-munin}"
DEFAULT_PASS="${DEFAULT_PASS:-munin}"

# Default workspace (can be overridden)
WORK_BASE="${WORK_BASE:-$ROOT/workdir}"
WORK="$WORK_BASE/rootfs-$ARCH"

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

# If bind-mounted FS has nodev/noexec (common on macOS Docker mounts),
# debootstrap fails on mknod. Fall back to container-local /tmp.
pick_workdir() {
  local candidate="$1"
  $SUDO mkdir -p "$candidate"
  local probe="$candidate/.munin_devnull_probe"

  if $SUDO mknod "$probe" c 1 3 >/dev/null 2>&1; then
    $SUDO rm -f "$probe"
    echo "$candidate"
  else
    echo "/tmp/muninos-work/rootfs"
  fi
}

WORK="$(pick_workdir "$WORK")"
if [[ "$WORK" == "/tmp/muninos-work/rootfs" ]]; then
  echo "[rootfs] info: source mount does not allow device nodes; using container-local $WORK"
fi

$SUDO mkdir -p "$WORK" "$BUILD/live"

# Persist effective rootfs path for validators/next stages
$SUDO mkdir -p "$BUILD"
echo "$WORK" | $SUDO tee "$BUILD/rootfs.path" >/dev/null
echo "$ARCH" | $SUDO tee "$BUILD/arch" >/dev/null

if [[ ! -f "$WORK/.debootstrap_done" ]]; then
  $SUDO debootstrap --arch="$ARCH" bookworm "$WORK" http://deb.debian.org/debian
  $SUDO touch "$WORK/.debootstrap_done"
fi

if [[ "$ARCH" == "arm64" ]]; then
  KERNEL_PKG="linux-image-arm64"
else
  KERNEL_PKG="linux-image-amd64"
fi

PKGS="$(tr '\n' ' ' < "$PKGS_FILE") $KERNEL_PKG"
$SUDO chroot "$WORK" bash -lc "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGS"

# create default user for login (future ISOs)
$SUDO chroot "$WORK" bash -lc "id -u '$DEFAULT_USER' >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo,audio,video,netdev '$DEFAULT_USER'"
$SUDO chroot "$WORK" bash -lc "echo '$DEFAULT_USER:$DEFAULT_PASS' | chpasswd"
$SUDO chroot "$WORK" bash -lc "passwd -u '$DEFAULT_USER' >/dev/null 2>&1 || true"

# ensure root has password too (same default; user should rotate after first login)
$SUDO chroot "$WORK" bash -lc "echo 'root:$DEFAULT_PASS' | chpasswd"

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

# ship selected local model(s) only when available
if [[ -d "$ROOT/build/models" ]]; then
  $SUDO mkdir -p "$WORK/opt/muninos/models"
  $SUDO rsync -a "$ROOT/build/models/" "$WORK/opt/muninos/models/"
fi

# ensure executable scripts
$SUDO chmod +x \
  "$WORK/usr/local/bin/munin-firstboot" \
  "$WORK/usr/local/bin/munin-firstboot-wizard" \
  "$WORK/usr/local/bin/munin-core" \
  "$WORK/usr/local/bin/munin-sts" \
  "$WORK/usr/local/bin/munin-ui" \
  "$WORK/usr/local/bin/munin-brain" \
  "$WORK/usr/local/bin/munin-audio" || true

# enable systemd units in image root
$SUDO chroot "$WORK" bash -lc 'systemctl enable munin-firstboot.service munin-core.service munin-sts.service munin-ui.service munin-brain.service munin-audio.service || true'

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
