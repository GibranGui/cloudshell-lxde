#!/bin/bash
# Setup LXDE via Docker (dorowu/ubuntu-desktop-lxde-vnc) di Google Cloud Shell.
# Jalankan: bash docker-desktop.sh
set -e

echo "[1/4] Install Docker..."
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker.io
fi
docker --version

echo "[2/4] Start Docker daemon (Cloud Shell tidak pakai systemd)..."
sudo service docker start 2>/dev/null || sudo dockerd >/tmp/dockerd.log 2>&1 &
for i in $(seq 1 15); do docker info >/dev/null 2>&1 && break; sleep 2; done
docker info >/dev/null 2>&1 || { echo "Docker daemon gagal start, cek /tmp/dockerd.log"; exit 1; }
echo "Docker daemon OK."

echo "[3/4] Hapus container lama & jalankan desktop..."
docker rm -f lxde 2>/dev/null || true
docker run -d --name lxde --privileged -p 6070:80 dorowu/ubuntu-desktop-lxde-vnc

echo "[4/4] Menunggu web UI..."
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:6070/vnc.html || true)
  [ "$code" = "200" ] && break
  sleep 2
done
curl -s -o /dev/null -w "Web UI port 6070 -> HTTP %{http_code}\n" http://localhost:6070/vnc.html

echo ""
echo "SELESAI! Buka Web preview Cloud Shell (ikon jendela+gigi) -> Change configuration -> port 6070."
echo "Password VNC default: vncpassword  (ganti via -e VNC_PASSWORD=xxx saat docker run)"
