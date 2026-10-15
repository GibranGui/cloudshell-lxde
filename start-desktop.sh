#!/usr/bin/env bash
# start-desktop.sh — jalankan LXDE di Cloud Shell (tanpa sudo, tanpa root)
# Cara pakai:  bash start-desktop.sh
set -e

export DISPLAY=:99
RES="1280x800x24"      # resolusi desktop, ubah sesuai selera
VNC_PORT=5900
NOVNC_PORT=6080

# Jangan pakai set -e di bagian ini: pkill mengembalikan kode non-zero
# saat tidak ada proses yang cocok, yang akan membuat skrip berhenti diam-diam.
set +e

echo "[1/5] Membersihkan sesi lama..."
pkill -x Xvfb 2>/dev/null || true
pkill -f "novnc --listen $NOVNC_PORT" 2>/dev/null || true
pkill x11vnc 2>/dev/null || true
pkill -f startlxde 2>/dev/null || true
pkill lxsession 2>/dev/null || true
rm -f /tmp/.X11-unix/X99 /tmp/.X99-lock 2>/dev/null || true
sleep 1

echo "[2/5] Menjalankan X server virtual (Xvfb $DISPLAY)..."
Xvfb $DISPLAY -screen 0 $RES >/tmp/xvfb.log 2>&1 &
sleep 2

echo "[3/5] Menjalankan D-Bus + LXDE session..."
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
lxsession >/tmp/lxsession.log 2>&1 &
sleep 2
startlxde >/tmp/lxde.log 2>&1 &
sleep 3

if ! pgrep -x Xvfb >/dev/null; then
  echo "ERROR: Xvfb mati. Isi /tmp/xvfb.log:"
  tail -10 /tmp/xvfb.log
  exit 1
fi

echo "[4/5] Menjalankan VNC server (port $VNC_PORT)..."

# Deteksi dini: apakah x11vnc & novnc sudah terpasang?
MISSING=""
command -v x11vnc   >/dev/null 2>&1 || MISSING="$MISSING x11vnc"
{ [ -x /usr/share/novnc/utils/novnc_proxy ] || command -v websockify >/dev/null 2>&1; } \
  || MISSING="$MISSING novnc/websockify"
if [ -n "$MISSING" ]; then
  echo "ERROR: Paket belum terpasang:$MISSING"
  echo "Jalankan dulu: sudo apt-get update && sudo apt-get install -y --no-install-recommends lxde x11vnc novnc websockify dbus-x11 xterm"
  echo "(atau: bash install-desktop.sh)"
  exit 1
fi

# Bersihkan x11vnc lama agar tidak bentrok port
pkill -x x11vnc 2>/dev/null; sleep 1

x11vnc -display $DISPLAY -forever -shared -rfbport $VNC_PORT -nopw \
       -bg -o /tmp/x11vnc.log >/dev/null 2>&1
sleep 2
if ! pgrep -x x11vnc >/dev/null; then
  echo "ERROR: x11vnc gagal start. Isi log:"
  echo "----------------- /tmp/x11vnc.log -----------------"
  tail -20 /tmp/x11vnc.log 2>/dev/null || echo "(log kosong — x11vnc bahkan tidak sempat menulis)"
  echo "--------------------------------------------------------"
  echo "Cek juga: DISPLAY=$DISPLAY, Xvfb hidup? -> pgrep -a Xvfb"
  exit 1
fi
echo "OK: x11vnc jalan (PID $(pgrep -x x11vnc | head -1)) di port $VNC_PORT"

echo "[5/5] Menjalankan noVNC web client (port $NOVNC_PORT)..."
if [ -x /usr/share/novnc/utils/novnc_proxy ]; then
  nohup /usr/share/novnc/utils/novnc_proxy --vnc localhost:$VNC_PORT \
         --listen $NOVNC_PORT >/tmp/novnc.log 2>&1 &
elif command -v websockify >/dev/null 2>&1; then
  nohup websockify --web=/usr/share/novnc $NOVNC_PORT localhost:$VNC_PORT \
       >/tmp/novnc.log 2>&1 &
else
  echo "ERROR: novnc/websockify belum terpasang. Jalankan dulu install-desktop.sh"
  exit 1
fi
sleep 3
if ! curl -s -o /dev/null http://localhost:$NOVNC_PORT/vnc.html; then
  echo "ERROR: noVNC tidak merespon di port $NOVNC_PORT. Cek: tail -20 /tmp/novnc.log"
  exit 1
fi

echo ""
echo "=========================================================="
echo " LXDE sudah jalan! Buka lewat menu Cloud Shell:"
echo "   ikon 'Web preview' (gambar jendela+gigi) -> Port $NOVNC_PORT"
echo " URL-nya otomatis jadi https://...cs-...-$NOVNC_PORT.cs.cloudshell.dev"
echo " Kosongkan password VNC lalu klik Connect."
echo "=========================================================="
