#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD="$ROOT/build"
WORK="$ROOT/workdir/rootfs"

# Use effective rootfs path produced by build-rootfs (important on macOS Docker fallback)
if [[ -f "$BUILD/rootfs.path" ]]; then
  WORK="$(cat "$BUILD/rootfs.path")"
fi

fail() { echo "[validate] ERROR: $*" >&2; exit 1; }
pass() { echo "[validate] OK: $*"; }

[[ -d "$WORK" ]] || fail "rootfs not found at $WORK (run: make rootfs)"

# Required runtime binaries in image
for b in /opt/muninos/bin/munin-core /opt/muninos/bin/munin-sts /opt/muninos/bin/munin-ui /opt/muninos/bin/munin-brain /opt/muninos/bin/munin-audio; do
  [[ -x "$WORK$b" ]] || fail "missing executable $b in rootfs"
  pass "found $b"
done

# Required service units
for s in munin-core.service munin-sts.service munin-ui.service munin-brain.service munin-audio.service munin-firstboot.service; do
  [[ -f "$WORK/etc/systemd/system/$s" ]] || fail "missing unit $s"
  pass "found unit $s"
done

# Required UI assets
[[ -f "$WORK/opt/muninos/ui/index.html" ]] || fail "missing UI index.html"
pass "found UI assets"

# Runtime config
[[ -f "$WORK/etc/default/munin-sts" ]] || fail "missing /etc/default/munin-sts"
pass "found STS default env"

# Build artifacts (if validate called post-iso)
if [[ -f "$BUILD/muninos-dev.iso" ]]; then
  pass "ISO present: $BUILD/muninos-dev.iso"
fi

echo "[validate] All checks passed."
