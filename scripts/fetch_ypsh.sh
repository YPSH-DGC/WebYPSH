#!/usr/bin/env bash
set -euo pipefail

STABLE_URL="https://ypsh-dgc.github.io/YPSH/channels/stable.txt"
RAW_BASE="https://github.com/YPSH-DGC/YPSH"
OUT_DIR="${1:-artifacts}"
mkdir -p "$OUT_DIR"

echo "[*] Fetching stable tag from: $STABLE_URL"
TAG="$(curl -fsSL "$STABLE_URL" | tr -d ' \t\r\n')"
if [[ -z "$TAG" ]]; then
  echo "[-] Empty tag from stable.txt" >&2; exit 1
fi
echo "[+] Stable tag: $TAG"
echo "$TAG" > "$OUT_DIR/tag.txt"

PY_URL="$RAW_BASE/releases/download/$TAG/YPSH-python-3.py"
REQ_URL="$RAW_BASE/raw/refs/tags/$TAG/requirements.txt"

echo "[*] Downloading ypsh.py: $PY_URL"
curl -fL --retry 3 --retry-delay 2 -o "$OUT_DIR/ypsh.py" "$PY_URL"
echo "[*] Downloading requirements.txt: $REQ_URL"
curl -fL --retry 3 --retry-delay 2 -o "$OUT_DIR/requirements.txt" "$REQ_URL"

# 簡易健全性チェック
if [[ $(wc -c < "$OUT_DIR/ypsh.py") -lt 1024 ]]; then
  echo "[-] ypsh.py looks too small" >&2; exit 1
fi
if [[ $(wc -l < "$OUT_DIR/requirements.txt") -lt 1 ]]; then
  echo "[-] requirements.txt is empty?" >&2; exit 1
fi

echo "[+] Fetched to: $OUT_DIR (tag=$(cat "$OUT_DIR/tag.txt"))"
