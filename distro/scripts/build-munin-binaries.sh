#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/build/munin-bin"

mkdir -p "$OUT"

if ! command -v cargo >/dev/null 2>&1; then
  echo "[munin-bin] cargo not found. install Rust toolchain first."
  exit 1
fi

build_one() {
  local crate_dir="$1"
  local bin_name="$2"
  echo "[munin-bin] building $bin_name from $crate_dir"
  cargo build --release --manifest-path "$ROOT/$crate_dir/Cargo.toml"
  cp "$ROOT/$crate_dir/target/release/$bin_name" "$OUT/$bin_name"
}

build_one "munin-core" "munin-core"
build_one "munin-sts" "munin-sts"
build_one "munin-brain" "munin-brain"
build_one "munin-audio" "munin-audio"
build_one "munin-ui-service" "munin-ui"

echo "[munin-bin] done -> $OUT"
ls -lh "$OUT"
