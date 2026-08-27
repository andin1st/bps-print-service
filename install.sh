#!/usr/bin/env bash
# ==============================================================================
# BPS Oneliner-Script: Automated Installer (Version 3 - Curl-Based)
# Resolves: Git LFS binary corruption, removes 'git' dependency on client side.
# Downloads BPS.exe from GitHub Releases and appsettings.json via Curl.
# ==============================================================================

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
        error "Skrip ini harus dijalankan dengan hak akses root (sudo)."
        echo "  Gunakan perintah: curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash"
        exit 1
    fi
    if [[ -z "${SUDO_USER:-}" ]]; then
        error "Mohon jalankan skrip ini menggunakan 'sudo bash', bukan langsung login sebagai root."
        exit 1
    fi
}

# 2. Deteksi Distribusi Linux & Tentukan Package Manager
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
    fi
    info "Mendeteksi distribusi sistem operasi: ${DISTRO_ID}"
}

# 3. Instal Wine, curl, dan dependensi yang sesuai untuk distro target
install_dependencies() {
    info "Memulai instalasi Wine, Curl, dan dependensi pendukung..."
    
    # Deteksi Fedora
    if [[ "$DISTRO_ID" == "fedora" ]]; then
        info "Menjalankan instalasi paket untuk Fedora..."
        dnf install -y wine wine-mono mingw32-wine-gecko mingw64-wine-gecko curl
        
    # Deteksi Debian / Ubuntu / Linux Mint / Pop!_OS
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        info "Menjalankan instalasi paket untuk Debian/Ubuntu..."
        apt-get update
        apt-get install -y wine wine-mono wine-gecko curl
        
        # Opsional: Instal fonts Microsoft jika tersedia di sistem
        if apt-cache show ttf-mscorefonts-installer &>/dev/null; then
            info "Menginstal ttf-mscorefonts-installer..."
            echo ttf-mscorefonts-installer msttcorefontshandler/accepted-mscorefonts-eula select true | debconf-set-selections || true
            apt-get install -y ttf-mscorefonts-installer || warn "Gagal menginstal font Microsoft Core Fonts, instalasi BPS akan tetap dilanjutkan."
        fi

    # Deteksi Arch Linux / Manjaro
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        info "Menjalankan instalasi paket untuk Arch Linux..."
        pacman -Syu --noconfirm wine wine-mono wine-gecko curl

    else
        warn "Distribusi Linux Anda (${DISTRO_ID}) tidak terdaftar secara resmi."
        warn "Pastikan 'wine', 'wine-mono', 'wine-gecko', dan 'curl' sudah terpasang secara manual."
        read -p "Apakah Anda ingin tetap melanjutkan instalasi? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Instalasi dibatalkan oleh pengguna."
            exit 1
        fi
    fi
    
    info "Semua dependensi berhasil dikonfigurasi."
}

# 4. Pengaturan Direktori dan Pengunduhan Berkas BPS via Curl
download_app() {
    # Dapatkan HOME directory asli milik user non-root yang memanggil sudo
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    APP_NAME="BPS Print Service"
    APP_DIR="$USER_HOME/bps-print-service"
    LOG_FILE="/tmp/bps.log"

    # Definisikan URL unduhan
    # CATATAN: BPS.exe wajib diletakkan di GitHub Release agar tidak terkena limitasi LFS 130-byte pointer
    BPS_EXE_URL="https://github.com/andin1st/bps-print-service/releases/latest/download/BPS.exe"
    APP_SETTINGS_URL="https://raw.githubusercontent.com/andin1st/bps-print-service/main/appsettings.json"

    info "Mengonfigurasi direktori aplikasi untuk user: ${REAL_USER}"
    info "Target folder aplikasi: ${APP_DIR}"

    # Buat direktori dengan permission milik user asli
    sudo -u "$REAL_USER" mkdir -p "$APP_DIR"

    # Unduh berkas konfigurasi appsettings.json
    info "Mengunduh file konfigurasi appsettings.json..."
    sudo -u "$REAL_USER" curl -L -s -o "$APP_DIR/appsettings.json" "$APP_SETTINGS_URL"

    # Unduh berkas utama BPS.exe dari GitHub Releases
    info "Mengunduh berkas biner BPS.exe (90 MB) dari GitHub Releases..."
    info "Ini mungkin memakan waktu beberapa saat tergantung kecepatan internet..."
    
    # Jalankan curl sebagai user asli agar hak kepemilikan file benar
    if ! sudo -u "$REAL_USER" curl -L -# -o "$APP_DIR/BPS.exe" "$BPS_EXE_URL"; then
        error "Gagal mengunduh BPS.exe!"
        error "Pastikan Anda sudah mengunggah BPS.exe ke rilis terbaru (GitHub Releases) di repositori Anda."
        exit 1
    fi

    # Verifikasi ukuran file unduhan untuk memastikan bukan file pointer LFS (130 byte) atau error 404 HTML
    FILE_SIZE=$(wc -c <"$APP_DIR/BPS.exe")
    if [[ $FILE_SIZE -lt 100000 ]]; then
        error "File BPS.exe yang terunduh rusak atau terlalu kecil ($FILE_SIZE bytes)."
        error "Kemungkinan penyebab:"
        error "1. BPS.exe belum diunggah sebagai 'Asset' di GitHub Releases Anda."
        error "2. Tautan rilis tidak valid atau belum dipublikasikan sebagai 'Public'."
        error "Silakan buat Release baru di https://github.com/andin1st/bps-print-service/releases dan unggah BPS.exe di sana."
        rm -f "$APP_DIR/BPS.exe"
        exit 1
    fi

    # Atur kepemilikan agar menjadi milik user biasa (bukan root)
    chown -R "$REAL_USER:$REAL_USER" "$APP_DIR"
    chmod +x "$APP_DIR/BPS.exe"
}

# 5. Tambahkan alias bps-run ke .bashrc dan .zshrc
setup_alias() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    ALIAS_CMD="alias bps-run=\"cd \$HOME/bps-print-service && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &\""
    
    info "Mendaftarkan alias 'bps-run' ke file profil shell..."

    # Tambahkan ke .bashrc jika ada
    if [[ -f "$USER_HOME/.bashrc" ]]; then
        if ! grep -Fq "alias bps-run=" "$USER_HOME/.bashrc"; then
            echo -e "\n# BPS Print Service Alias\n$ALIAS_CMD" >> "$USER_HOME/.bashrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc"
            info "Alias ditambahkan ke ~/.bashrc"
        else
            info "Alias sudah terdaftar di ~/.bashrc"
        fi
    fi

    # Tambahkan ke .zshrc jika ada
    if [[ -f "$USER_HOME/.zshrc" ]]; then
        if ! grep -Fq "alias bps-run=" "$USER_HOME/.zshrc"; then
            echo -e "\n# BPS Print Service Alias\n$ALIAS_CMD" >> "$USER_HOME/.zshrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.zshrc"
            info "Alias ditambahkan ke ~/.zshrc"
        else
            info "Alias sudah terdaftar di ~/.zshrc"
        fi
    fi
}

# 6. Inisialisasi Prefiks Wine sebagai User Biasa
init_wine_prefix() {
    REAL_USER="$SUDO_USER"
    info "Melakukan inisialisasi Wine Prefix untuk user '${REAL_USER}' agar berjalan lancar..."
    sudo -u "$REAL_USER" env DISPLAY=:0 wineboot --init
}

# 7. Tampilkan Ringkasan Hasil Pemasangan
print_summary() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    APP_DIR="$USER_HOME/bps-print-service"
    LOG_FILE="/tmp/bps.log"

    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    info "Instalasi BPS Print Service Selesai!"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    echo "  Folder Aplikasi   :  $APP_DIR"
    echo "  Berkas Log        :  $LOG_FILE"
    echo ""
    echo "  Cara Mengaktifkan Alias Baru Anda:"
    echo -e "  - Jalankan perintah: ${YELLOW}source ~/.bashrc${NC} (atau ${YELLOW}source ~/.zshrc${NC})"
    echo ""
    echo "  Cara Mengelola Layanan BPS:"
    echo -e "  - ${YELLOW}Menjalankan Sekarang${NC}   : bps-run"
    echo -e "  - ${YELLOW}Menghentikan Layanan${NC}  : pkill -f BPS.exe"
    echo ""
    echo -e "  ${YELLOW}CATATAN PENTING UNTUK DEVELOPER:${NC}"
    echo "  Pastikan Anda telah mengunggah file BPS.exe (90 MB) asli ke"
    echo "  halaman Releases di repositori GitHub Anda agar link unduhan"
    echo "  tersebut dapat bekerja bagi seluruh klien Anda!"
    echo -e "${GREEN}=======================================================${NC}"
}

main() {
    check_root
    detect_distro
    install_dependencies
    download_app
    setup_alias
    init_wine_prefix
    print_summary
}

main "$@"
