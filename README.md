# Cloud Shell LXDE — Panduan Lengkap

Panduan menjalankan desktop **LXDE** di **Google Cloud Shell** dan mengaksesnya lewat VNC/noVNC dari browser maupun Termux (HP Android). Termasuk cara menjaga sesi tetap hidup, menyambung ulang setelah koneksi putus, dan mereset disk ketika penuh.

> Cocok untuk skenario: membuka Discord + game berbasis tombol klik (button) di desktop LXDE, dibiarkan berjalan meski browser/HP ditutup. Perlu diingat: sesi Cloud Shell punya batas **±24 jam**, jadi restart harian tetap diperlukan.

---

## 0. Prasyarat & fakta penting

| Hal | Keterangan |
|---|---|
| OS Cloud Shell | Debian 12, sudo tanpa password, ~5 GB RAM |
| Batas idle | 60 menit tanpa aktivitas terminal → instance dihentikan (akali dengan `keepalive.sh`) |
| Batas keras | Instance berhenti otomatis setiap ±24 jam — **tidak bisa dilewati skrip apa pun** |
| Disk persisten | Hanya `$HOME` (~5 GB) yang bertahan antar sesi; paket `apt` hilang saat restart |
| Browser/HP ditutup | Proses latar belakang (desktop, macro, Discord) **tetap jalan** selama instance hidup |

---

## 1. Reset disk Cloud Shell (jika internal penuh)

Dua tingkat reset:

### a) Reset ringan (hapus paket desktop saja)
```bash
bash reset-desktop.sh
```
Menghentikan semua proses X/VNC dan purge paket `lxde`, `x11vnc`, `novnc`, dll. File di `$HOME` tidak tersentuh.

### b) Reset total (factory reset, hapus seluruh `$HOME`)
Lewat UI browser (paling aman & resmi):
1. Buka [shell.cloud.google.com](https://shell.cloud.google.com)
2. Klik ikon **⚙️ Settings** (pojok kanan atas bar biru)
3. Pilih **"Reset shell"** → konfirmasi

Atau lihat panduan perintah:
```bash
bash factory-reset.sh   # tampilkan perintah rm -rf $HOME, jalankan manual setelah simpan data
```
> ⚠️ Reset total menghapus SEMUA isi `$HOME`. Simpan dulu file penting (`git push`, atau unduh via menu ⋮ → Download).

Cek pemakaian disk sebelum/sesudah reset:
```bash
df -h / $HOME
```

---

## 2. Instalasi LXDE (dari awal)

```bash
git clone https://github.com/GibranGui/cloudshell-lxde && cd cloudshell-lxde
bash install-desktop.sh     # apt install lxde x11vnc novnc websockify dbus-x11 xterm (~150 MB)
bash start-desktop.sh       # Xvfb :99 → lxsession/startlxde → x11vnc:5900 → noVNC:6080
```

`start-desktop.sh` bersifat idempoten — jalankan ulang kapan saja untuk restart stack tanpa instalasi ulang.

### Buka desktop di browser
- Cloud Shell: menu **"Web preview" → Change configuration → Preview on port 6080** → klik **Connect** (tanpa password).
- Jika muncul error CORS/403 pada "Open on port", gunakan Web preview (bukan Open on port biasa).

### Jalankan aplikasi (mis. Discord)
Di dalam desktop: menu LXDE → Terminal. Contoh pakai Chromium (versi web Discord):
```bash
sudo apt-get install -y chromium
chromium --no-sandbox https://discord.com/app
```
Macro klik di dalam desktop dengan `xdotool`:
```bash
sudo apt-get install -y xdotool
xdotool search --name "Discord" windowactivate key Return   # contoh interaksi
```

---

## 3. Jaga sesi agar tidak timeout (anti-idle 60 menit)

```bash
nohup bash keepalive.sh > /dev/null 2>&1 &    # mulai: simulasi aktivitas tiap 5 menit
pgrep -f keepalive.sh                          # cek status (tampil PID = jalan)
pkill -f keepalive.sh                          # hentikan
```

**Tidak perlu membuka 2 terminal.** Perintah di atas menjalankan keepalive di *latar belakang* dengan `nohup ... &`, sehingga terminal yang sama tetap bisa dipakai untuk perintah lain, dan prosesnya selamat meski tab/browser ditutup. Kamu cukup satu terminal untuk semuanya:

```bash
# contoh alur lengkap dalam SATU terminal:
bash install-desktop.sh
bash start-desktop.sh
nohup bash keepalive.sh > /dev/null 2>&1 &     # <- masuk background, terminal tetap bebas
chromium https://discord.com/app &             # aplikasi lain juga bisa &
```

Opsional watchdog (auto-restart stack desktop jika ada proses mati):
```bash
nohup bash cloudshell-watcher.sh > /dev/null 2>&1 &
```

Catatan: VNC/browser yang terbuka **tidak** dihitung sebagai aktivitas oleh Cloud Shell — hanya input ke terminal. Karena itu `keepalive.sh` wajib dijalankan dari terminal.

---

## 4. Menyambung ulang setelah browser/Termux ditutup

**Fakta kunci:** menutup browser/SSH **tidak** menghentikan instance selama masih dalam batas idle/24 jam. Proses desktop tetap jalan.

### Cara A — browser
Buka ulang [shell.cloud.google.com](https://shell.cloud.google.com). Jika instance masih hidup, kamu tersambung ke sesi yang sama (terminal memang terlihat fresh, tapi proses latar belakang tetap aktif). Cek:
```bash
pgrep -a x11vnc && echo "desktop masih jalan"
```
Lalu buka lagi via Web preview port 6080.

### Cara B — Termux (SSH tunnel)
1. Prepare sekali di Termux:
   ```bash
   pkg install -y openssh
   ```
2. Dapatkan akses SSH (dari mesin lain: `gcloud cloud-shell ssh`, atau salin perintah connect dari menu Cloud Shell).
3. Dari Termux, jalankan skrip reconnect:
   ```bash
   bash connect-termux.sh <USER>@<INSTANCE>.cloudshell.dev -p 6022
   ```
   Skrip membuat tunnel `-L 6080:localhost:6080`, lalu buka browser HP: `http://localhost:6080/vnc.html` → Connect.

Jika terminal baru terasa "fresh" tapi `pgrep x11vnc` kosong → instance sudah restart → ulangi langkah bagian 2 (instalasi paket hilang, tapi `$HOME` aman).

---

## 5. Batasan realistis (jujur soal ini)

- **Restart ±24 jam wajib manual**: tidak ada API publik untuk membangunkan Cloud Shell dari luar (Koyeb/cron tidak bisa). Kamu harus buka tab Cloud Shell minimal sekali sehari.
- **Game/cloud gaming berat tidak cocok**: CPU throttling, tanpa GPU. Discord + macro klik ringan masih oke.
- Keamanan: x11vnc hanya listen di `127.0.0.1`; akses eksternal semata-mata lewat HTTPS forwarding milik akunmu. Tambahkan `-passwd` pada x11vnc bila perlu.

## 6. Daftar isi repo

| File | Fungsi |
|---|---|
| `install-desktop.sh` | Pasang paket LXDE + VNC/noVNC |
| `start-desktop.sh` | Jalankan stack desktop (idempoten) |
| `keepalive.sh` | Anti-idle (aktivitas palsu tiap 5 menit) |
| `cloudshell-watcher.sh` | Watchdog auto-restart stack |
| `connect-termux.sh` | Reconnect via SSH tunnel dari Termux |
| `reset-desktop.sh` | Reset ringan (purge paket desktop) |
| `factory-reset.sh` | Panduan reset total `$HOME` |
| `desktop-lxde.sh` | Versi portabel satu-skrip (Codespaces juga bisa) |
