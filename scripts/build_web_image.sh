#!/usr/bin/env bash
set -euo pipefail

# 入力: artifacts ディレクトリ（fetch_ypsh.sh の出力）
ART_DIR="${1:-artifacts}"
[[ -f "$ART_DIR/ypsh.py" && -f "$ART_DIR/requirements.txt" ]] || { echo "[-] artifacts missing"; exit 1; }

# 出力: web/assets/hda.img  を作る
DIST=${DIST:-bookworm}
ARCH=${ARCH:-amd64}
IMG_MB=${IMG_MB:-4096}
WORKDIR=${WORKDIR:-/tmp/ypsh_web_build}
ROOT="$WORKDIR/rootfs"
IMG="$WORKDIR/hda.img"
MNT="$WORKDIR/mnt"

sudo rm -rf "$WORKDIR"; mkdir -p "$WORKDIR" web/assets
sudo apt-get update
sudo apt-get install -y debootstrap e2fsprogs rsync ca-certificates

echo "[*] debootstrap $DIST ($ARCH)"
sudo debootstrap --arch="$ARCH" "$DIST" "$ROOT" http://deb.debian.org/debian

echo "[*] Install runtime deps inside rootfs"
sudo chroot "$ROOT" /bin/bash -euxc "
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-pip python3-setuptools \
    locales tzdata ca-certificates curl less nano procps coreutils base64 \
    libzstd1 libssl3 libglib2.0-0 libx11-6 libxext6 libxrender1 \
    libxcb1 libxcb-util1 libxcb-keysyms1 libxcb-image0 libxcb-icccm4 \
    libxcb-shape0 libxcb-shm0 libxcb-randr0 libxcb-render0 libxcb-xfixes0 \
    libxcb-xinerama0 libxcb-xkb1 libxkbcommon0 libxkbcommon-x11-0 \
    libfontconfig1 libfreetype6 libgcc-s1 libstdc++6
  locale-gen en_US.UTF-8 || true
"

echo "[*] Copy app sources"
sudo mkdir -p "$ROOT/root"
sudo cp "$ART_DIR/ypsh.py" "$ROOT/root/ypsh.py"
sudo cp "$ART_DIR/requirements.txt" "$ROOT/root/requirements.txt"

echo "[*] pip install (system, no venv)"
sudo chroot "$ROOT" /bin/bash -euxc "
  python3 -m pip install --upgrade pip
  pip install --no-cache-dir -r /root/requirements.txt
  apt-get clean
  rm -rf /var/lib/apt/lists/*
"

echo "[*] Make ext4 disk image (${IMG_MB}MB)"
dd if=/dev/zero of="$IMG" bs=1M count="$IMG_MB"
mkfs.ext4 -F "$IMG"
mkdir -p "$MNT"
sudo mount -o loop "$IMG" "$MNT"

echo "[*] Copy rootfs → image"
sudo rsync -aHAX \
  --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp \
  "$ROOT/ " "$MNT/"

sudo mkdir -p "$MNT"/{proc,sys,dev,tmp}
sudo umount "$MNT"

mv "$IMG" web/assets/hda.img
echo "[+] Built: web/assets/hda.img ($(du -h web/assets/hda.img | awk '{print $1}'))"
