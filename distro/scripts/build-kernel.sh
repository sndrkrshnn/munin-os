#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT/build/kernel"
KERNEL_SRC="${KERNEL_SRC:-$ROOT/workdir/linux}"
DEFCONFIG="$ROOT/distro/kernel/configs/blueprint_defconfig"

mkdir -p "$BUILD_DIR"

if [[ ! -d "$KERNEL_SRC" ]]; then
  echo "[kernel] Linux source not found at $KERNEL_SRC"
  echo "[kernel] Clone kernel source first, e.g.:"
  echo "git clone --depth 1 https://github.com/torvalds/linux.git $KERNEL_SRC"
  exit 1
fi

pushd "$KERNEL_SRC" >/dev/null
cp "$DEFCONFIG" .config
yes "" | make olddefconfig
make -j"$(nproc)"
cp arch/x86/boot/bzImage "$BUILD_DIR/bzImage"
popd >/dev/null

echo "[kernel] Done -> $BUILD_DIR/bzImage"
