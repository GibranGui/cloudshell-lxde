# Menjalankan LXDE Desktop di Cloud Shell / GitHub Codespaces

Jalankan desktop Linux ringan (LXDE) headless di browser lewat VNC-over-WebSocket (noVNC).
Satu skrip portabel untuk Google Cloud Shell dan GitHub Codespaces.

## Cara pakai

```bash
# 1. Clone repo ini (di Cloud Shell atau terminal Codespaces)
git clone <URL_REPO_INI>
cd <NAMA_REPO>

# 2. Jalankan — skrip otomatis menginstal paket yang hilang lalu menyalakan desktop
bash desktop-lxde.sh
```

### Buka desktopnya di browser

| Lingkungan | Langkah |
|---|---|
| **Cloud Shell** | Menu "Web preview" → *Change configuration* → **Preview on port 6080** → klik **Connect** (tanpa password) |
| **Codespaces** | Tab **Ports** → port `6080` → ubah **Visibility = Public** (atau forward via VS Code Remote) → buka URL forwaded → Connect |
| **Lokal/VM lain** | `ssh -L 6080:localhost:6080 user@host` lalu buka `http://localhost:6080/vnc.html` |

## Konsumsi sumber daya (terukur, Debian 12)

| Item | Nilai |
|---|---|
| Paket terpasang (`lxde-core`, `xvfb`, `x11vnc`, `novnc`, `websockify`, `x11-utils`) | ~130 MB disk |
| RAM saat desktop aktif (openbox + lxpanel + pcmanfm + Xvfb + x11vnc + websockify) | ~490 MB total terpakai |
| Proses desktop berjalan | 7 proses |

Pilihan hemat RAM:
- `lxde-core` (dipakai skrip) jauh lebih ringan daripada metapaket `lxde` penuh.
- Untuk tampilan lebih modern gunakan `xfce4` (~600–800 MB RAM) — ganti nama paket di baris instalasi.
- Hindari GNOME/KDE: butuh systemd & >1 GB RAM, tidak cocok untuk instance kecil.

## Reset / menghapus lagi

```bash
sudo apt-get purge -y 'lx*' openbox* lxde* x11vnc novnc websockify xvfb && sudo apt-get autoremove --purge -y
pkill -f 'Xvfb|lxsession|openbox|lxpanel|pcmanfm|x11vnc|websockify'
```

## Variabel lingkungan

`DISPLAY_NUM` (default 99), `RES` (1280x800x24), `VNC_PORT` (5900, hanya localhost), `NOVNC_PORT` (6080).

## Keamanan

x11vnc listen hanya di `127.0.0.1` tanpa password; akses eksternal hanya lewat HTTPS forwarding platform (sesi akunmu sendiri). Tambahkan `-passwd` pada baris x11vnc bila perlu lapisan ekstra.

## Catatan

Instance kedua platform ini ephemeral: setelah timeout/restart, paket & proses hilang. Skrip ini idempoten — jalankan ulang kapan saja untuk membangun kembali semuanya.
