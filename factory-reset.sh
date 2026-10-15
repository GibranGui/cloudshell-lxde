#!/bin/bash
# factory-reset.sh - Reset total Cloud Shell (setara tombol "Reset" di UI)
# PERINGATAN: Menghapus SEMUA isi $HOME (persistent disk). Instance akan restart.
# Simpan dulu file penting: git push, atau cp ke /tmp lalu download via Cloud Shell IDE.

echo "=== FACTORY RESET CLOUD SHELL ==="
echo "Langkah 1/3: Hentikan semua proses desktop/VNC/keepalive..."
pkill -f x11vnc      2>/dev/null
pkill -f novnc       2>/dev/null
pkill -f websockify  2>/dev/null
pkill -f Xvfb        2>/dev/null
pkill -f keepalive   2>/dev/null
pkill -f cloudshell-watcher 2>/dev/null
pkill -x openbox     2>/dev/null
pkill -x lxpanel     2>/dev/null
pkill -f pcmanfm     2>/dev/null
echo "OK."

echo "Langkah 2/3: Backup skrip ke /tmp (sementara)..."
mkdir -p /tmp/cs-backup
cp "$HOME"/factory-reset.sh "$HOME"/install-desktop.sh "$HOME"/start-desktop.sh \
   "$HOME"/keepalive.sh "$HOME"/cloudshell-watcher.sh "$HOME"/connect-termux.sh \
   /tmp/cs-backup/ 2>/dev/null
echo "Skrip dicadangkan ke /tmp/cs-backup (bertahan sampai instance restart)."

echo "Langkah 3/3: Hapus persistent disk ($HOME)... 5 detik lagi!"
echo "Tekan Ctrl+C sekarang untuk membatalkan."
sleep 5

rm -rf "${HOME:?}/"* "${HOME:?}"/.[!.]* "${HOME:?}"/..?* 2>/dev/null
sync

echo ""
echo "=== HOME SUDAH KOSONG ==="
echo "Instance baru akan dibuat otomatis saat kamu membuka kembali tab Cloud Shell."
echo "Disk internal yang penuh juga ikut terformat ulang oleh Google saat restart ini."
echo ""
echo "Setelah buka tab baru, pulihkan skrip dengan:"
echo "  mkdir -p \$HOME && cp /tmp/cs-backup/*.sh \$HOME/ 2>/dev/null || echo 'Backup hilang (normal jika instance benar-benar baru), unduh ulang skrip dari repo Git.'"
