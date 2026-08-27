#!/usr/bin/env bash
# =============================================================================
# BPS Oneliner-Script: Automated Uninstaller (Version 3)
# Cleanly removes BPS Print Service, autostart entries, global wrappers, 
# and cleans up shell aliases from .bashrc and .zshrc.
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

# 1. Pastikan skrip dijalankan menggunakan sudo
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Skrip uninstaller ini harus dijalankan dengan hak akses root (sudo)."
        echo "  Gunakan perintah: sudo ./uninstall.sh"
        exit 1
    fi
    if [[ -z "${SUDO_USER:-}" ]]; then
        error "Mohon jalankan skrip ini menggunakan 'sudo ./uninstall.sh', bukan langsung login sebagai root."
        exit 1
    fi
}

main() {
    check_root

    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    APP_NAME="BPS Print Service"
    APP_DIR="$USER_HOME/bps-print-service"
    GLOBAL_BIN="/usr/local/bin/bps-run"
    AUTOSTART_FILE="$USER_HOME/.config/autostart/bps-print-service.desktop"
    LOG_FILE="/tmp/bps.log"

    echo ""
    echo -e "${YELLOW}=======================================================${NC}"
    echo -e "  Menghapus ${APP_NAME} dari Sistem"
    echo -e "${YELLOW}=======================================================${NC}"
    echo ""
    
    # Konfirmasi sebelum melanjutkan
    read -p "Apakah Anda yakin ingin menghapus BPS Print Service secara total? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Proses uninstall dibatalkan oleh pengguna."
        exit 0
    fi

    # 1. Menghentikan proses BPS.exe yang sedang berjalan
    info "Menghentikan semua proses BPS.exe yang aktif..."
    pkill -f BPS.exe 2>/dev/null || true
    sleep 1

    # 2. Menghapus perintah global wrapper
    if [[ -f "$GLOBAL_BIN" ]]; then
        info "Menghapus perintah global di $GLOBAL_BIN..."
        rm -f "$GLOBAL_BIN"
    fi

    # 3. Menghapus konfigurasi autostart
    if [[ -f "$AUTOSTART_FILE" ]]; then
        info "Menghapus konfigurasi autostart di $AUTOSTART_FILE..."
        rm -f "$AUTOSTART_FILE"
    fi

    # 4. Menghapus folder aplikasi bps-print-service
    if [[ -d "$APP_DIR" ]]; then
        info "Menghapus folder aplikasi di $APP_DIR..."
        rm -rf "$APP_DIR"
    fi

    # 5. Menghapus file log sementara
    if [[ -f "$LOG_FILE" ]]; then
        info "Membersihkan berkas log di $LOG_FILE..."
        rm -f "$LOG_FILE"
    fi

    # 6. Menghapus alias bps-run dari .bashrc dan .zshrc
    info "Membersihkan entri alias dari konfigurasi shell..."

    # Bersihkan dari .bashrc
    if [[ -f "$USER_HOME/.bashrc" ]]; then
        if grep -q "bps-run" "$USER_HOME/.bashrc"; then
            # Hapus baris komentar dan baris alias
            sed -i '/# BPS Print Service Alias/d' "$USER_HOME/.bashrc"
            sed -i '/alias bps-run=/d' "$USER_HOME/.bashrc"
            info "Alias bps-run berhasil dihapus dari ~/.bashrc"
        fi
    fi

    # Bersihkan dari .zshrc
    if [[ -f "$USER_HOME/.zshrc" ]]; then
        if grep -q "bps-run" "$USER_HOME/.zshrc"; then
            # Hapus baris komentar dan baris alias
            sed -i '/# BPS Print Service Alias/d' "$USER_HOME/.zshrc"
            sed -i '/alias bps-run=/d' "$USER_HOME/.zshrc"
            info "Alias bps-run berhasil dihapus dari ~/.zshrc"
        fi
    fi

    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    info "${APP_NAME} BERHASIL DIHAPUS DENGAN BERSIH!"
    echo -e "${GREEN}=======================================================${NC}"
    echo "  Layanan, pintasan autostart, log, folder instalasi, dan"
    echo "  perintah alias 'bps-run' telah dibersihkan secara total."
    echo ""
    echo "  Catatan: Paket Wine tidak ikut dihapus karena mungkin masih"
    echo "  digunakan oleh aplikasi lain di komputer Anda."
    echo -e "${GREEN}=======================================================${NC}"
}

main "$@"
