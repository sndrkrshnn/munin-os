#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${SRC_DIR:-$ROOT/build/models}"
DEST="${DEST:-/opt/muninos/models}"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "[models] source dir missing: $SRC_DIR" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

$SUDO mkdir -p "$DEST"
$SUDO rsync -a "$SRC_DIR/" "$DEST/"

echo "[models] installed to $DEST"
ls -lh "$SRC_DIR"
