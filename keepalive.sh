#!/usr/bin/env bash
# keepalive.sh - cegah Cloud Shell idle-timeout (60 menit).
# Aman: hanya menyentuh tty milik sesi terminal sendiri; jika tidak ada tty aktif, diam.
# Jalankan:  nohup bash keepalive.sh >/dev/null 2>&1 &   Hentikan: pkill -f keepalive.sh

INTERVAL="${1:-300}"
while true; do
    for tty in $(who -a 2>/dev/null | awk '$1=="pts"||$1=="/dev/pts"{print $2}'); do
        dev="/dev/$tty"; [ -e "$dev" ] || dev="/dev/$tty"
        printf ' \b' > "$dev" 2>/dev/null || true
    done
    sleep "$INTERVAL"
done
