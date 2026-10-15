#!/bin/bash
# reset.sh — reset desktop LXDE Docker di Google Cloud Shell
# Cara pakai:  bash reset.sh          (reset ringan: hapus container + bersihkan docker)
#              bash reset.sh --full   (reset berat: + prune image & cache docker)
# Setelah reset, jalankan ulang: bash docker-desktop.sh

set -u
FULL="${1:-}"

echo "[1/4] Menghentikan & menghapus container lxde..."
if command -v docker >/dev/null 2>&1; then
  docker rm -f lxde 2>/dev/null && echo "  - container lxde dihapus." || echo "  - tidak ada container lxde."
else
  echo "  - docker belum terpasang, lewati."
fi

echo "[2/4] Membersihkan proses Xvfb/VNC/noVNC lama (jika ada sisa manual)..."
pkill -f 'Xvfb :99' 2>/dev/null
pkill x11vnc 2>/dev/null
pkill -f websockify 2>/dev/null
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null
echo "  - selesai."

echo "[3/4] Membersihkan log..."
rm -f /tmp/xvfb.log /tmp/lxsession.log /tmp/startlxde.log /tmp/x11vnc.log /tmp/novnc.log /tmp/docker.log 2>/dev/null
echo "  - selesai."

echo "[4/4] Pembersihan docker..."
if command -v docker >/dev/null 2>&1; then
  if [ "$FULL" = "--full" ]; then
    echo "  - mode FULL: menghapus SEMUA image & cache docker (termasuk image dorowu ±2-3 GB)."
    docker system prune -af 2>/dev/null || true
  else
    echo "  - membersihkan container dangling saja (image tetap disimpan agar pull cepat lagi)."
    docker container prune -f 2>/dev/null || true
  fi
fi

echo ""
echo "RESET SELESAI. Untuk menjalankan ulang desktop:"
echo "  bash docker-desktop.sh"
echo ""
echo "Catatan: ini TIDAK mereset disk/home Cloud Shell. Untuk reset total instance:"
echo "  Buka shell.cloud.google.com -> ikon Settings -> Reset shell (data \$HOME ikut terhapus)."
