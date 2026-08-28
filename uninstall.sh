#!/usr/bin/env bash
# =============================================================================
# BPS Oneliner-Script: Automated Uninstaller (Version 3)
# Cleans up all traces of BPS Print Service & Systemd Integration cleanly.
# =============================================================================

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ $EUID -ne 0 ]]; then
    error "Skrip ini harus dijalankan dengan hak akses root (sudo)."
    echo "  Gunakan perintah: sudo ./uninstall.sh"
    exit 1
fi

if [[ -z "${SUDO_USER:-}" ]]; then
    error "Mohon jalankan skrip ini menggunakan 'sudo', bukan langsung login sebagai root."
    exit 1
fi

REAL_USER="$SUDO_USER"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
USER_ID=$(getent passwd "$REAL_USER" | cut -d: -f3)

APP_NAME="BPS Print Service"
APP_DIR="$USER_HOME/bps-print-service"
SERVICE_FILE="$USER_HOME/.config/systemd/user/bps.service"

echo "======================================================="
echo "  Penghapusan (Uninstall) $APP_NAME"
echo "======================================================="
read -p "Apakah Anda yakin ingin menghapus layanan ini dari sistem? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Proses pembatalan uninstall oleh pengguna."
    exit 0
fi

# 1. Hentikan dan Nonaktifkan Systemd Service
if [[ -f "$SERVICE_FILE" ]]; then
    info "Menghentikan dan menonaktifkan systemd service..."
    sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$USER_ID" systemctl --user stop bps.service || true
    sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$USER_ID" systemctl --user disable bps.service || true
    rm -f "$SERVICE_FILE"
    sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$USER_ID" systemctl --user daemon-reload || true
    info "Systemd service berhasil dihapus."
fi

# 2. Hentikan proses Wine BPS jika masih tersisa
info "Memastikan seluruh proses BPS.exe dan Wine dimatikal..."
pkill -f BPS.exe 2>/dev/null || true
sleep 1

# 3. Hapus Wrapper Global /usr/local/bin/bps-run
if [[ -f "/usr/local/bin/bps-run" ]]; then
    info "Menghapus perintah global bps-run..."
    rm -f "/usr/local/bin/bps-run"
fi

# 4. Hapus folder utama aplikasi
if [[ -d "$APP_DIR" ]]; then
    info "Menghapus folder aplikasi di: $APP_DIR"
    rm -rf "$APP_DIR"
fi

# 5. Bersihkan file log sementara
if [[ -f "/tmp/bps.log" ]]; then
    info "Menghapus file log sementara..."
    rm -f "/tmp/bps.log"
fi

# 6. Bersihkan sisa alias jika ada di .bashrc atau .zshrc
info "Membersihkan entri alias lama di profil shell..."
if [[ -f "$USER_HOME/.bashrc" ]]; then
    sed -i '/# BPS Print Service Alias/d' "$USER_HOME/.bashrc"
    sed -i '/alias bps-run=/d' "$USER_HOME/.bashrc"
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc"
fi

if [[ -f "$USER_HOME/.zshrc" ]]; then
    sed -i '/# BPS Print Service Alias/d' "$USER_HOME/.zshrc"
    sed -i '/alias bps-run=/d' "$USER_HOME/.zshrc"
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.zshrc"
fi

echo ""
echo -e "${GREEN}=======================================================${NC}"
info "Uninstall Selesai dengan Sukses!"
echo "  Seluruh berkas aplikasi, autostart, dan konfigurasi"
echo "  BPS Print Service telah dihapus dari sistem."
echo -e "${GREEN}=======================================================${NC}"