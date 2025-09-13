#!/usr/bin/env bash
set -euo pipefail

STABLE_URL="https://ypsh-dgc.github.io/YPSH/channels/stable.txt"
RAW_BASE="https://github.com/YPSH-DGC/YPSH"
OUT_DIR="${1:-artifacts}"
mkdir -p "$OUT_DIR"

echo "[*] Fetching stable tag from: $STABLE_URL"
TAG="$(curl -fsSL "$STABLE_URL" | tr -d ' \t\r\n')"
[[ -n "$TAG" ]] || { echo "[-] Empty tag"; exit 1; }
echo "$TAG" > "$OUT_DIR/tag.txt"

PY_URL="$RAW_BASE/releases/download/$TAG/YPSH-python-3.py"
REQ_URL="$RAW_BASE/raw/refs/tags/$TAG/requirements.txt"

echo "[*] Downloading: $PY_URL"
curl -fL --retry 3 --retry-delay 2 -o "$OUT_DIR/ypsh.py" "$PY_URL"
echo "[*] Downloading: $REQ_URL"
curl -fL --retry 3 --retry-delay 2 -o "$OUT_DIR/requirements.txt" "$REQ_URL"

[[ $(wc -c < "$OUT_DIR/ypsh.py") -ge 1024 ]]
[[ $(wc -l < "$OUT_DIR/requirements.txt") -ge 1 ]]

echo "[+] OK tag=$(cat "$OUT_DIR/tag.txt")"
