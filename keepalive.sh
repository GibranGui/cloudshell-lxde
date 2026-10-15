#!/usr/bin/env bash
# keepalive.sh - cegah Cloud Shell idle-timeout (60 menit) dengan aktivitas terminal.
# Jalankan di latar belakang:  nohup bash keepalive.sh > /dev/null 2>&1 &
# Hentikan:                    pkill -f keepalive.sh

INTERVAL="${1:-300}"   # detik antar "aktivitas" (default 5 menit)

while true; do
    # ketik spasi + hapus -> menghasilkan I/O di terminal, dianggap aktivitas
    printf ' \b'
    sleep "$INTERVAL"
done
