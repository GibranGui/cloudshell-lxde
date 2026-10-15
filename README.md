# Cloud Shell LXDE — Panduan Instalasi MANUAL

Panduan **langkah demi langkah secara manual** (tanpa skrip otomatis) untuk menjalankan
desktop **LXDE** di **Google Cloud Shell** dan mengaksesnya lewat browser via noVNC.
Cara ini dipilih karena lebih mudah didiagnosa: setiap langkah dijalankan satu per satu,
sehingga kalau ada error, langsung terlihat di langkah mana.

---

## Fakta penting sebelum mulai

| Hal | Keterangan |
|---|---|
| OS Cloud Shell | Debian 12, sudo tanpa password, ~5 GB RAM |
| Batas idle | 60 menit tanpa aktivitas terminal → instance mati (lihat Langkah 7 keep-alive) |
| Batas keras | Instance berhenti otomatis setiap ±24 jam — tidak bisa dilewati |
| Persisten | Hanya `$HOME` yang bertahan; paket `apt` hilang saat restart → ulangi Langkah 1–6 tiap hari |
| Browser/HP ditutup | Proses latar belakang (desktop, Discord, macro) tetap jalan selama instance hidup |

---

## Langkah 0 — Reset disk jika penuh

Jika muncul error disk penuh:

- **Cara resmi:** buka https://shell.cloud.google.com → klik ikon **⚙️ Settings** → **"Reset shell"**.
  ⚠️ Ini menghapus SEMUA isi `$HOME`. Simpan dulu file penting ke GitHub.
- **Reset ringan (hapus paket desktop saja):**
  ```bash
  pkill -f 'Xvfb :99'; pkill x11vnc; pkill -f websockify; pkill -f novnc
  sudo apt-get purge -y lxde x11vnc novnc websockify
  sudo apt-get autoremove -y
  df -h /
  ```

Setelah reset total, mulai dari Langkah 1 lagi.

---

## Langkah 1 — Install paket (jalankan manual, bukan skrip)

Salin perintah ini **apa adanya** ke terminal Cloud Shell:

```bash
sudo apt-get update
```

Lalu:

```bash
sudo apt-get install -y --no-install-recommends \
  lxde x11vnc novnc websockify dbus-x11 xterm xdotool net-tools
```

Tunggu sampai selesai (±150 MB download). Setelah itu **verifikasi instalasi**:

```bash
which Xvfb x11vnc lxsession startlxde
ls /usr/share/novnc/utils/novnc_proxy
```

✅ Jika semua menampilkan path (contoh `/usr/bin/Xvfb`), instalasi berhasil.
❌ Jika ada yang kosong/keluar pesan `not found`, berarti Langkah 1 belum selesai atau gagal —
ulangi `sudo apt-get update` lalu install lagi. **Jangan lanjut sebelum semua terdeteksi.**

> Error umum: `start-desktop.sh: line 25: Xvfb: command not found`
> Artinya paket belum terpasang di instance ini (instance baru setelah reset/restart 24 jam).
> Solusinya: jalankan ulang Langkah 1.

---

## Langkah 2 — Bersihkan sesi lama

```bash
pkill -f 'Xvfb :99'
pkill x11vnc
pkill -f websockify
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
```

(Aman dijalankan walau tidak ada proses lama — abaikan pesan "no process found".)

---

## Langkah 3 — Jalankan X server virtual (Xvfb)

```bash
nohup Xvfb :99 -screen 0 1280x800x24 >/tmp/xvfb.log 2>&1 &
sleep 3
pgrep -a Xvfb
export DISPLAY=:99
```

✅ `pgrep -a Xvfb` harus menampilkan baris seperti `12345 Xvfb :99 ...`
❌ Jika kosong → lihat errornya: `cat /tmp/xvfb.log` (biasanya `command not found` = kembali ke Langkah 1)

---

## Langkah 4 — Jalankan LXDE desktop

```bash
eval "$(dbus-launch --sh-syntax)"
nohup lxsession >/tmp/lxsession.log 2>&1 &
sleep 2
nohup startlxde >/tmp/startlxde.log 2>&1 &
sleep 4
pgrep -a openbox
pgrep -a lxpanel
```

✅ Keduanya harus menampilkan proses = desktop sudah jalan.
❌ Jika kosong → `cat /tmp/startlxde.log` dan `cat /tmp/lxsession.log` untuk melihat errornya.

---

## Langkah 5 — Jalankan VNC server (port 5900)

```bash
nohup x11vnc -display :99 -forever -shared -rfbport 5900 -localhost >/tmp/x11vnc.log 2>&1 &
sleep 3
netstat -ltn | grep 5900
```

✅ Harus muncul baris `... 127.0.0.1:5900 ... LISTEN`
❌ Jika tidak → `tail -20 /tmp/x11vnc.log` (jika `command not found` = kembali ke Langkah 1)

> ⚠️ Port 5900 adalah protokol VNC mentah — TIDAK BISA dibuka di browser. Jangan coba akses 5900 dari browser.

---

## Langkah 6 — Jalankan noVNC bridge (port 6080) + verifikasi

```bash
nohup /usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 >/tmp/novnc.log 2>&1 &
sleep 4
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:6080/vnc.html
```

✅ Harus menampilkan `HTTP 200`
❌ Selain itu → `tail -20 /tmp/novnc.log` dan pastikan path `/usr/share/novnc/utils/novnc_proxy` ada (`ls` di Langkah 1).

### Buka desktop di browser

1. Di jendela terminal Cloud Shell, lihat **link port 6080** yang otomatis muncul di bawah terminal → klik.
2. ATAU klik ikon **"Web preview"** (jendela + gigi) di kanan atas terminal → **Change configuration** → masukkan port **6080** → **Save & Run**.
3. URL terbuka seperti `https://...cs-xxxx-6080.cs.cloudshell.dev` → klik **Connect** (tanpa password).
4. Desktop LXDE muncul. ✔

> ❗ Jangan ketik `localhost:6080` atau `5900` manual di browser HP/Termux — itu hanya berlaku di dalam mesin Cloud Shell. Akses resmi hanya lewat Web Preview di atas.

---

## Langkah 7 — Keep-alive (anti timeout 60 menit)

Jalankan di terminal yang sama (proses di latar belakang, tidak perlu terminal kedua):

```bash
nohup bash -c 'while true; do sleep 300; printf " "; done' >/dev/null 2>&1 &
```

Cek: `pgrep -fa "sleep 300"` → hentikan: `pkill -f "sleep 300"`

Ingat: keep-alive hanya mencegah idle-timeout 60 menit. **Batas 24 jam tetap tidak bisa dilewati** — setelah itu instance mati dan kamu harus mengulang Langkah 1–7 (file di `$HOME` aman).

---

## Langkah 8 — Macro klik (misal tombol game/Discord)

Di dalam desktop LXDE (jendela Terminal), contoh memakai `xdotool`:

```bash
export DISPLAY=:99
xdotool mousemove 640 400 click 1     # geser mouse & klik kiri
xdotool type "halo"                   # mengetik
```

Loop sederhana tiap 60 detik:
```bash
while true; do xdotool mousemove 640 400 click 1; sleep 60; done
```

---

## Diagnosa cepat (kalau macet, cek tabel ini)

| Gejala | Penyebab | Solusi |
|---|---|---|
| `Xvfb: command not found` | Paket belum terpasang di instance ini | Ulangi Langkah 1, verifikasi dengan `which Xvfb` |
| Skrip macet tanpa pesan | Paket hilang / proses lama menggantung | Ikuti panduan manual Langkah 0–6 di atas |
| `5900` ditolak browser | Salah konsep: 5900 bukan HTTP | Pakai port **6080** via Web Preview |
| `localhost:6080` dari HP gagal | Tidak ada tunnel ke mesin Cloud Shell | Pakai Web Preview, atau SSH tunnel Termux |
| CORS/error 403 di preview | Bug Cloud Shell lama | Reload halaman, atau buka link port dari bawah terminal |
| Desktop hitam/blank | LXDE mati | `cat /tmp/startlxde.log`, ulangi Langkah 4 |
| Sesi hilang tiap hari | Batas 24 jam Google | Normal — ulangi Langkah 1–7 setiap hari |
| Disk penuh | Image/paket menumpuk | Reset via ⚙️ Settings → Reset shell |

Log untuk diagnosa: `/tmp/xvfb.log`, `/tmp/lxsession.log`, `/tmp/startlxde.log`, `/tmp/x11vnc.log`, `/tmp/novnc.log`

---

## Ringkasan harian (setelah restart 24 jam)

```bash
# Langkah 1
sudo apt-get update && sudo apt-get install -y --no-install-recommends lxde x11vnc novnc websockify dbus-x11 xterm xdotool net-tools
# Langkah 2-6 (copy-paste berurutan), lalu:
nohup bash -c 'while true; do sleep 300; printf " "; done' >/dev/null 2>&1 &   # Langkah 7
```
Lalu buka Web Preview port 6080. Selesai.
