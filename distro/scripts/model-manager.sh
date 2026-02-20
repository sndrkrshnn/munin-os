#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="${MANIFEST:-$ROOT/models/manifest.json}"
TARGET_DIR="${TARGET_DIR:-$ROOT/build/models}"
TIER="${TIER:-auto}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "[models] manifest not found: $MANIFEST" >&2
  exit 1
fi

if [[ "$TIER" == "auto" ]]; then
  if command -v "$ROOT/munin-brain/target/release/munin-brain" >/dev/null 2>&1; then
    TIER=$("$ROOT/munin-brain/target/release/munin-brain" profile | python3 -c 'import sys,json;print(json.load(sys.stdin)["tier"])')
  else
    # Safe default for low resource systems
    TIER="Tier1Mobile"
  fi
fi

mkdir -p "$TARGET_DIR"

readarray -t MODEL_INFO < <(python3 - "$MANIFEST" "$TIER" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
t=sys.argv[2]
p=m["presets"].get(t)
if not p:
    raise SystemExit(f"unknown tier: {t}")
print(p["model_id"])
print(p["file"])
print(p["url"])
PY
)

MODEL_ID="${MODEL_INFO[0]}"
MODEL_FILE="${MODEL_INFO[1]}"
MODEL_URL="${MODEL_INFO[2]}"

OUT="$TARGET_DIR/$MODEL_FILE"

echo "[models] selected tier: $TIER"
echo "[models] model: $MODEL_ID"
echo "[models] file: $MODEL_FILE"

if [[ -f "$OUT" ]]; then
  echo "[models] already present: $OUT"
  exit 0
fi

if command -v curl >/dev/null 2>&1; then
  curl -L --fail --progress-bar "$MODEL_URL" -o "$OUT"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$OUT" "$MODEL_URL"
else
  echo "[models] need curl or wget" >&2
  exit 1
fi

echo "[models] downloaded: $OUT"
