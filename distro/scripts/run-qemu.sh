#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISO="$ROOT/build/blueprintos-dev.iso"
RAM="${RAM:-4096}"
CPUS="${CPUS:-2}"

if [[ ! -f "$ISO" ]]; then
  echo "[qemu] ISO not found: $ISO"
  echo "Run: make iso"
  exit 1
fi

QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
  echo "[qemu] $QEMU_BIN not found. Install qemu-system-x86"
  exit 1
fi

KVM_FLAG=""
if [[ -e /dev/kvm ]]; then
  KVM_FLAG="-enable-kvm -cpu host"
fi

exec "$QEMU_BIN" \
  $KVM_FLAG \
  -m "$RAM" \
  -smp "$CPUS" \
  -boot d \
  -cdrom "$ISO" \
  -device ich9-intel-hda -device hda-duplex \
  -net nic -net user
