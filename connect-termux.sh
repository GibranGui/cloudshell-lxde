#!/usr/bin/env bash
# connect-termux.sh - jalankan DI TERMUX (bukan di Cloud Shell).
# Menyambung ulang ke sesi Cloud Shell yang MASIH BERJALAN di server Google,
# lalu tunnel port noVNC (6080) ke localhost Termux.
#
# Prasyarat:
#   pkg install openssh
#   Salin PERINTAH SSH lengkap dari halaman Cloud Shell (tombol panah di dekat
#   prompt >_cloudshell@...), contoh:
#     ssh -p 6022 -i ~/.ssh/<kunci> \
#         -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
#         -o "ServerAliveInterval=60" -o "ServerAliveIntervalKeepAliveCountMax=3" \
#         USERNAME-PROFILNAME@REGION-cLOUDSHELL-PROJECT-ID.cloudshell.dev
#
# CARA PAKAI:
#   1) Edit CS_SSH_BASE di bawah, tempel perintah ssh hasil salinan tadi.
#      (HANYA bagian ssh-nya; jangan sertakan perintah setelah '--' jika ada.)
#   2) Jalankan:  bash connect-termux.sh
#   3) Buka browser HP:  http://localhost:6080/vnc.html  -> klik Connect.
#
# CATATAN PENTING:
#   - Jangan buka port 5900 langsung dari browser/Termux! Port itu hanya bisa
#     diakses dari DALAM instance (via tunnel). Browser tidak mengerti protokol
#     mentah VNC anyway -> pakai noVNC (6080).
#   - Jika terminal ini ditutup, sesi Cloud Shell tetap berjalan (proses desktop
#     hidup di server); cukup jalankan skrip ini lagi untuk reconnect.

# ==== EDIT INI: tempel perintah ssh Cloud Shell-mu di sini ====
CS_SSH_BASE='ssh -p 6022 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=60" cloudshell@GANTI-DENGAN-HOST.CLOUDSHELL.DEV'
# ==============================================================

if [[ "$CS_SSH_BASE" == *"GANTI-DENGAN-HOST"* ]]; then
  echo "ERROR: edit dulu variabel CS_SSH_BASE di skrip ini."
  echo "Salin perintah ssh lengkap dari halaman Cloud Shell (ikon panah dekat prompt)."
  exit 1
fi

echo "[1/3] Cek/nyalakan desktop + keep-alive di Cloud Shell..."
$CS_SSH_BASE 'bash -lc "
  cd \$HOME/cloudshell-lxde 2>/dev/null || cd \$HOME/workspace/cloudshell-lxde 2>/dev/null || true;
  pgrep -f keepalive.sh >/dev/null || nohup bash keepalive.sh >/dev/null 2>&1 &
  if ! pgrep -f novnc >/dev/null; then
    command -v Xvfb >/dev/null || sudo apt-get update && sudo apt-get install -y --no-install-recommends lxde x11vnc novnc websockify dbus-x11 xterm;
    bash start-desktop.sh;
  fi;
  echo SESSION-AKTIF"'

echo "[2/3] Tunnel: localhost:6080 (Termux) -> localhost:6080 (Cloud Shell)..."
echo "[3/3] Setelah koneksi mapan, buka browser HP:"
echo "        http://localhost:6080/vnc.html  -> kosongkan password -> Connect"
exec $CS_SSH_BASE -N -L 6080:localhost:6080
