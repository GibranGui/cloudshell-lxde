#!/usr/bin/env bash
# cloudshell-watcher.sh - jalankan DI DALAM Cloud Shell (bukan di Koyeb).
# Fungsi: menjaga sesi tetap hidup selama mungkin:
#   1. keep-alive aktivitas terminal tiap 5 menit (hindari idle-timeout 60 mnt)
#   2. watchdog LXDE/VNC/noVNC: restart otomatis jika proses mati
# Catatan: batas keras 24 jam per instance TIDAK bisa dilewati skrip ini.
set -u

INTERVAL=${INTERVAL:-300}          # detik antar keep-alive
LOG=$HOME/cloudshell-watcher.log

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

is_alive() { pgrep -f "$1" >/dev/null 2>&1; }

restart_stack() {
  log "Watchdog: stack mati, menjalankan start-desktop.sh"
  if [ -x "$HOME/start-desktop.sh" ]; then
    bash "$HOME/start-desktop.sh" >>"$LOG" 2>&1
  elif [ -x /workspace/start-desktop.sh ]; then
    bash /workspace/start-desktop.sh >>"$LOG" 2>&1
  else
    log "ERROR: start-desktop.sh tidak ditemukan di \$HOME maupun /workspace"
  fi
}

log "Watcher dimulai (interval ${INTERVAL}s)"

while true; do
  # 1) Aktivitas terminal -> cegah idle timeout
  printf ' \b' > /dev/tty 2>/dev/null || true

  # 2) Watchdog desktop/VNC
  if ! is_alive "Xvfb" || ! is_alive "x11vnc" || ! is_alive "lxsession"; then
    restart_stack
  fi

  sleep "$INTERVAL"
done
