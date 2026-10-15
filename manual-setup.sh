#!/bin/bash
# Cara MANUAL langkah demi langkah - tanpa skrip start-desktop.sh
# Jalankan baris per baris di terminal Cloud Shell.

# --- Bersihkan sesi lama ---
pkill -f 'Xvfb :99'; pkill x11vnc; pkill -f websockify; pkill -f novnc
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# --- [1] X server virtual ---
nohup Xvfb :99 -screen 0 1280x800x24 >/tmp/xvfb.log 2>&1 &
sleep 3
pgrep -a Xvfb || { echo "Xvfb GAGAL:"; cat /tmp/xvfb.log; }

export DISPLAY=:99

# --- [2] D-Bus + LXDE ---
eval "$(dbus-launch --sh-syntax)"
nohup lxsession >/tmp/lxsession.log 2>&1 &
sleep 2
nohup startlxde >/tmp/startlxde.log 2>&1 &
sleep 4
pgrep -a openbox && pgrep -a lxpanel   # harus muncul = desktop jalan

# --- [3] VNC server (port 5900, localhost only) ---
nohup x11vnc -display :99 -forever -shared -rfbport 5900 -localhost >/tmp/x11vnc.log 2>&1 &
sleep 3
netstat -ltn | grep 5900 || tail -5 /tmp/x11vnc.log

# --- [4] noVNC bridge (port 6080) ---
nohup /usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 >/tmp/novnc.log 2>&1 &
sleep 4
curl -s -o /dev/null -w "noVNC HTTP %{http_code}\n" http://localhost:6080/vnc.html

echo "SELESAI -> Buka Web preview Cloud Shell, port 6080, klik Connect (tanpa password)."
