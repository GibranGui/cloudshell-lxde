#!/usr/bin/env bash
# install-desktop.sh — pasang LXDE + noVNC di Google Cloud Shell
# Cloud Shell sudah punya sudo (tanpa password) dan Xvfb bawaan.
set -e

if [ "$(whoami)" != "root" ]; then SUDO="sudo"; else SUDO=""; fi

echo "[1/3] apt update..."
$SUDO apt-get update -qq

echo "[2/3] Pasang LXDE + X11/VNC tools (~150 MB)..."
$SUDO apt-get install -y -qq --no-install-recommends \
  lxde x11vnc novnc websockify dbus-x11 xterm

echo "[3/3] Selesai. Jalankan desktop dengan:"
echo "    bash start-desktop.sh"
