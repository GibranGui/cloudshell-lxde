#!/usr/bin/env bash
# connect-termux.sh - jalankan DI TERMUX (bukan di Cloud Shell).
# Menyambung ulang ke sesi Cloud Shell yang MASIH BERJALAN di server Google,
# lalu tunnel port noVNC (6080) ke localhost Termux.
# Prasyarat: pkg install openssh ; pernah login via ssh cloudshell@... (password token).
# Ganti <PROFIL> dengan nama profil Cloud Shell-mu (lihat perintah ssh di halaman Cloud Shell).

CS_SSH="ssh cloudshell@<PROFIL>.cloudshell.dev"
CS_CMD='bash -lc "cd \$HOME/workspace 2>/dev/null || cd \$HOME; pgrep -f keepalive.sh >/dev/null || nohup bash keepalive.sh >/dev/null 2>&1 & pgrep -f novnc_proxy >/dev/null || bash start-desktop.sh; echo OK-SESSION-AKTIF"'

echo "[1/2] Nyalakan/cek sesi + desktop di Cloud Shell..."
$CS_SSH "$CS_CMD"

echo "[2/2] Buka tunnel VNC: buka browser -> http://localhost:6080/vnc.html (Connect)"
ssh -L 6080:localhost:6080 cloudshell@<PROFIL>.cloudshell.dev
