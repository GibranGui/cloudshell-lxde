#!/usr/bin/env bash
# desktop-lxde.sh — jalankan LXDE headless + noVNC di Linux manapun (Cloud Shell, Codespaces, dsb.)
# Hemat RAM: hanya komponen inti LXDE (openbox + lxpanel + pcmanfm), tanpa aplikasi berat.
set -u

DISPLAY_NUM=${DISPLAY_NUM:-99}
RES=${RES:-1280x800x24}
VNC_PORT=${VNC_PORT:-5900}
NOVNC_PORT=${NOVNC_PORT:-6080}
export DISPLAY=:$DISPLAY_NUM

log() { echo "[desktop] $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 1. Pasang paket jika belum ada ----------
if ! have startlxde || ! have x11vnc || ! have websockify; then
  if have sudo || [ "$(id -u)" = "0" ]; then
    SUDO="sudo"; [ "$(id -u)" = "0" ] && SUDO=""
    log "Menginstal paket desktop (lxde-core, xvfb, x11vnc, novnc)..."
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update -qq
    # lxde-core = openbox+lxpanel+pcmanfm+lxsession (~lebih ringan dari metapaket 'lxde')
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      lxde-core lxappearance xterm dbus-x11 xvfb x11vnc novnc websockify x11-utils
  else
    echo "ERROR: butuh akses root/sudo untuk instalasi." >&2; exit 1
  fi
fi

# ---------- 2. Matikan instance lama jika ada ----------
pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null
pkill -f "x11vnc.*:$DISPLAY_NUM" 2>/dev/null
pkill -f websockify 2>/dev/null
pkill -f "python3 -m http.server $NOVNC_PORT" 2>/dev/null
sleep 1

# ---------- 3. X server virtual ----------
log "Menyalakan Xvfb di :$DISPLAY_NUM ($RES)..."
Xvfb :$DISPLAY_NUM -screen 0 $RES -nolisten tcp >/tmp/xvfb.log 2>&1 &
for i in $(seq 1 20); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done
xdpyinfo >/dev/null 2>&1 || { echo "Xvfb gagal start, lihat /tmp/xvfb.log"; exit 1; }

# ---------- 4. D-Bus session ----------
if ! have dbus-launch; then
  eval "$(dbus-daemon --session --fork --address=systemd: >/dev/null 2>&1; true)"
fi
eval "$(dbus-launch --sh-syntax 2>/dev/null || true)"
export $(dbus-launch 2>/dev/null | tr '\n' ' ') 2>/dev/null || true

# ---------- 5. Komponen LXDE ----------
log "Menyalakan lxsession/openbox..."
lxsession -s LXDE -e LXDE >/tmp/lxsession.log 2>&1 &
sleep 2
pgrep -x openbox >/dev/null || openbox &
pgrep -x lxpanel   >/dev/null || lxpanel &
pgrep -x pcmanfm   >/dev/null || (pcmanfm --desktop & )

# ---------- 6. VNC -> WebSocket (noVNC) ----------
log "Menyalakan x11vnc di port $VNC_PORT..."
x11vnc -display :$DISPLAY_NUM -forever -shared -rfbport $VNC_PORT -localhost -nopw -bg -o /tmp/x11vnc.log

log "Menyalakan noVNC/websockify di port $NOVNC_PORT..."
NOVNC_DIR=$(ls -d /usr/share/novnc /usr/share/websockify 2>/dev/null | head -1)
if [ -n "${NOVNC_DIR:-}" ] && [ -f "$NOVNC_DIR/vnc.html" ]; then
  websockify --web="$NOVNC_DIR" $NOVNC_PORT localhost:$VNC_PORT >/tmp/novnc.log 2>&1 &
else
  # fallback: vnc_lite.html via http.server + websockify telanjang
  mkdir -p /tmp/novnc-static
  cat > /tmp/novnc-static/index.html <<'EOF'
<!doctype html><html><head><meta charset="utf-8"><title>LXDE</title>
<script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.5.0/lib/rfb.js" type="module"></script>
<style>body{margin:0;background:#222;color:#eee;font-family:sans-serif;text-align:center;padding-top:40px}</style></head>
<body><p>Membuka koneksi VNC...</p>
<script type="module">
import RFB from 'https://cdn.jsdelivr.net/npm/@novnc/novnc@1.5.0/core/rfb.js';
const url='ws://'+location.hostname+':6080/websockify';
const rfb=new RFB(document.body,url);rfb.scaleViewport=true;
</script></body></html>
EOF
  websockify $NOVNC_PORT/localhost:$VNC_PORT localhost:$VNC_PORT >/tmp/novnc.log 2>&1 &
  (cd /tmp/novnc-static && python3 -m http.server $((NOVNC_PORT+1)) >/dev/null 2>&1 &)
fi

sleep 2
echo "=============================================================="
echo " LXDE LIVE! Buka lewat browser pada port $NOVNC_PORT"
echo " Cloud Shell  : Web preview -> Change configuration -> Preview on port $NOVNC_PORT"
echo " Codespaces   : Ports tab -> port $NOVNC_PORT -> Visibility Public -> klik URL"
echo " Lokal        : http://localhost:$NOVNC_PORT/vnc.html"
echo " Proses aktif : $(pgrep -c -f 'Xvfb|lxsession|openbox|lxpanel|pcmanfm|x11vnc|websockify') proses desktop berjalan"
echo " RAM terpakai : $(free -m | awk 'NR==2{print $3" MB"}')"
echo "=============================================================="
