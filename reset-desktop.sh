#!/usr/bin/env bash
# reset-desktop.sh — kembalikan instance ke kondisi bersih seperti semula:
# hentikan semua proses desktop/VNC + copot paket LXDE/noVNC yang pernah dipasang.
# Cara pakai:  bash reset-desktop.sh
set -e

if [ "$(whoami)" != "root" ]; then SUDO="sudo"; else SUDO=""; fi

echo "[1/3] Menghentikan proses desktop & VNC..."
pkill -f websockify 2>/dev/null || true
pkill -f novnc_proxy 2>/dev/null || true
pkill x11vnc 2>/dev/null || true
pkill startlxde 2>/dev/null || true
pkill lxsession 2>/dev/null || true
pkill lxpanel 2>/dev/null || true
pkill pcmanfm 2>/dev/null || true
pkill openbox 2>/dev/null || true
pkill Xvfb 2>/dev/null || true
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
sleep 1

echo "[2/3] Mencopot paket LXDE/VNC (purge) + autoremove dependensi..."
$SUDO apt-get purge -y -qq \
  lxde lxde-core lxde-common openbox-lxde-session \
  x11vnc novnc python3-novnc websockify python3-websockify \
  dbus-x11 xterm 2>/dev/null || true
DEBIAN_FRONTEND=noninteractive $SUDO apt-get autoremove --purge -y -qq || true

echo "[3/3] Verifikasi..."
if dpkg -l | grep -E '^i[^i]' | grep -qE 'lxde|x11vnc|novnc|websockify'; then
  echo "MASIH ADA paket tersisa:"
  dpkg -l | grep -E '^i[^i]' | grep -E 'lxde|x11vnc|novnc|websockify'
else
  echo "(bersih: tidak ada paket LXDE/VNC tersisa)"
fi
pgrep -a Xvfb >/dev/null 2>&1 && echo "PERINGATAN: masih ada proses Xvfb jalan" || echo "(proses desktop sudah berhenti semua)"
df -h / | tail -1

echo ""
echo "Selesai. Untuk memasang lagi dari nol:  bash install-desktop.sh && bash start-desktop.sh"
