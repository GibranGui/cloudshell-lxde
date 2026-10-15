# LXDE Desktop di Google Cloud Shell (via Docker)

Panduan ini menjalankan desktop **LXDE** penuh di Google Cloud Shell menggunakan image Docker `dorowu/ubuntu-desktop-lxde-vnc`, lalu diakses lewat browser melalui **Web Preview port 6070**. Tidak ada lagi instalasi manual Xvfb/x11vnc/noVNC — semua sudah dibundel di dalam container.

## Prasyarat
- Akun Google Cloud dengan Cloud Shell aktif (gratis).
- Sesi Cloud Shell hidup maksimal ±24 jam; setelah itu instance restart dan harus di-setup ulang (file di `$HOME` tetap aman).

## Cara Pakai (2 langkah)

### 1. Jalankan skrip setup
```bash
git clone https://github.com/GibranGui/cloudshell-lxde.git && cd cloudshell-lxde
bash docker-desktop.sh
```
Skrip akan: install Docker → start daemon → jalankan container LXDE → verifikasi web UI di port 6070.

Atau manual tanpa skrip:
```bash
sudo apt-get update && sudo apt-get install -y docker.io
sudo service docker start        # Cloud Shell tidak pakai systemd
docker run -d --name lxde --privileged -p 6070:80 dorowu/ubuntu-desktop-lxde-vnc
```

### 2. Buka desktopnya
Di terminal Cloud Shell, klik ikon **Web preview** (jendela + roda gigi) → **Change configuration** → ketik port **6070** → buka URL yang muncul. Login VNC dengan password default `vncpassword` (ganti dengan `-e VNC_PASSWORD=rahasia` saat `docker run`).

### 3. Anti-timeout (keep-alive)
Cloud Shell memutus sesi setelah 60 menit tanpa aktivitas **terminal**. Jalankan keepalive sekali saja (tetap jalan meski browser ditutup):
```bash
nohup bash keepalive.sh >/dev/null 2>&1 &
```
Cek: `pgrep -f keepalive.sh` · Hentikan: `pkill -f keepalive.sh`

## Perintah Berguna
| Kebutuhan | Perintah |
|---|---|
| Status container | `docker ps` |
| Lihat log desktop | `docker logs lxde` |
| Restart desktop | `docker restart lxde` |
| Hapus total | `docker rm -f lxde` |
| Buka terminal GUI di desktop | menu LXDE → Terminal (xterm) |

## Catatan Penting
- **Batas 24 jam:** instance Cloud Shell dihentikan otomatis ±24 jam. Solusi: buka kembali Cloud Shell, jalankan `bash docker-desktop.sh` lagi (image tersimpan di disk ephemeral, jadi pull ulang hanya jika instance benar-benar baru).
- **Disk:** image `dorowu/ubuntu-desktop-lxde-vnc` berukuran ±2–3 GB. Jika disk penuh: `docker system prune -a` atau reset via ⚙️ Settings → *Reset shell*.
- **Jangan akses port 5900 langsung** dari browser — gunakan Web Preview port **6070** (HTTP/noVNC bawaan image).
- **Browser HP / Termux ditutup ≠ sesi mati.** Container tetap jalan di server Google selama sesi aktif; cukup buka ulang Web Preview untuk reconnect.
- Game berat tidak cocok (tanpa GPU); cukup untuk browsing, Discord, dan macro klik ringan.

## Struktur Repo
- `docker-desktop.sh` — setup satu perintah (Docker + LXDE + verifikasi port 6070)
- `keepalive.sh` — jaga sesi agar tidak idle-timeout 60 menit
