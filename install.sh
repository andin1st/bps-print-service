#!/usr/bin/env bash
# =============================================================================
# BPS Oneliner-Script: Automated Installer (Version 9 - Wine 9.0+ WineHQ Stable)
# Features: 
#   1. Automatic distro detection & WineHQ Stable (Wine 9.0+) installation
#   2. Handles Ubuntu, Debian, and Linux Mint (Adds official WineHQ repos safely)
#   3. NO ttf-mscorefonts-installer in auto-setup (avoids EULA hanging)
#   4. Downloads BPS.exe and appsettings.json from GitHub using curl
#   5. Installs a Systemd User Service to prevent hanging on shutdown/restart!
#   6. Installs a global /usr/local/bin/bps-run service manager
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

# 3. Instal Wine 9.0+, curl, dan dependensi yang sesuai untuk distro target
install_dependencies() {
    info "Memulai instalasi Wine (WineHQ Stable), Curl, dan dependensi pendukung..."
    
    # Deteksi Fedora
    if [[ "$DISTRO_ID" == "fedora" ]]; then
        info "Menjalankan instalasi paket untuk Fedora..."
        dnf install -y wine wine-mono mingw32-wine-gecko mingw64-wine-gecko curl
        
    # Deteksi Debian / Ubuntu / Linux Mint / Pop!_OS
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        info "Mengonfigurasi repositori WineHQ Stable (Wine 9.0+) untuk Debian/Ubuntu/Mint..."
        
        # Pastikan curl terinstal terlebih dahulu
        apt-get update
        apt-get install -y curl gnupg2 ca-certificates
        
        # 1. Aktifkan arsitektur 32-bit (wajib untuk WineHQ)
        dpkg --add-architecture i386
        
        # 2. Buat folder keyrings dan unduh kunci repositori WineHQ
        mkdir -pm755 /etc/apt/keyrings
        curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/keyrings/winehq-archive.key
        
        # 3. Tentukan tipe OS (Debian vs Ubuntu)
        local OS_TYPE="ubuntu"
        if [[ "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" == *"debian"* ]]; then
            OS_TYPE="debian"
        fi
        
        # 4. Deteksi codename (misal: jammy, focal, noble, bookworm)
        local CODENAME=""
        if [[ -f /etc/os-release ]]; then
            CODENAME=$(grep -E "^UBUNTU_CODENAME=" /etc/os-release | cut -d= -f2 | tr -d '"' || echo "")
            if [[ -z "$CODENAME" ]]; then
                CODENAME=$(grep -E "^VERSION_CODENAME=" /etc/os-release | cut -d= -f2 | tr -d '"' || echo "")
            fi
        fi
        
        # Fallback jika codename tidak terdeteksi (misal Linux Mint / OS turunan lama)
        if [[ -z "$CODENAME" ]]; then
            if [[ "$OS_TYPE" == "ubuntu" ]]; then
                CODENAME="jammy" # Fallback untuk Linux Mint 21 / Ubuntu 22.04
            else
                CODENAME="bookworm" # Fallback untuk Debian 12
            fi
        fi
        
        info "Menambahkan sumber repositori WineHQ untuk ${OS_TYPE} (${CODENAME})..."
        
        # 5. Unduh file konfigurasi sumber repositori (.sources) resmi WineHQ
        curl -fsSL "https://dl.winehq.org/wine-builds/${OS_TYPE}/dists/${CODENAME}/winehq-${CODENAME}.sources" -o "/etc/apt/sources.list.d/winehq-${CODENAME}.sources"
        
        # 6. Perbarui indeks paket dan pasang paket winehq-stable
        info "Menjalankan instalasi paket 'winehq-stable' (Wine 9.0+)..."
        apt-get update
        apt-get install -y --install-recommends winehq-stable
        
    # Deteksi Arch Linux / Manjaro
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        info "Menjalankan instalasi paket untuk Arch Linux..."
        pacman -Syu --noconfirm wine curl

    else
        warn "Distribusi Linux Anda (${DISTRO_ID}) tidak terdaftar secara resmi."
        warn "Pastikan 'wine' (Wine 9.0+) dan 'curl' sudah terpasang secara manual."
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
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    APP_DIR="$USER_HOME/bps-print-service"
    
    # URL Unduhan
    BPS_EXE_URL="https://github.com/andin1st/bps-print-service/releases/latest/download/BPS.exe"
    APP_SETTINGS_URL="https://raw.githubusercontent.com/andin1st/bps-print-service/main/appsettings.json"

    info "Mengonfigurasi direktori aplikasi untuk user: ${REAL_USER}"
    info "Target folder aplikasi: ${APP_DIR}"

    # Buat direktori dengan permission milik user asli
    sudo -u "$REAL_USER" mkdir -p "$APP_DIR"

    # Unduh berkas konfigurasi appsettings.json jika belum ada
    if [[ ! -f "$APP_DIR/appsettings.json" ]]; then
        info "Mengunduh file konfigurasi appsettings.json..."
        sudo -u "$REAL_USER" curl -L -s -o "$APP_DIR/appsettings.json" "$APP_SETTINGS_URL"
    else
        info "Berkas appsettings.json sudah ada, melewati pengunduhan."
    fi

    # Unduh berkas utama BPS.exe dari GitHub Releases
    info "Mengunduh berkas biner BPS.exe (90 MB) dari GitHub Releases..."
    info "Ini mungkin memakan waktu beberapa saat tergantung kecepatan internet..."
    
    # Jalankan curl sebagai user asli agar hak kepemilikan file benar
    if ! sudo -u "$REAL_USER" curl -L -# -o "$APP_DIR/BPS.exe" "$BPS_EXE_URL"; then
        error "Gagal mengunduh BPS.exe!"
        error "Pastikan Anda sudah mengunggah BPS.exe ke rilis terbaru (GitHub Releases) di repositori Anda."
        exit 1
    fi

    # Verifikasi ukuran file unduhan untuk memastikan bukan file pointer LFS atau error 404 HTML
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

# 5. Konfigurasi Systemd User Service & Wrapper bps-run
setup_systemd_service() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    USER_ID=$(getent passwd "$REAL_USER" | cut -d: -f3)
    
    SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
    SERVICE_FILE="$SYSTEMD_DIR/bps.service"

    info "Mengonfigurasi Systemd User Service..."
    
    # Buat folder konfigurasi systemd user jika belum ada
    sudo -u "$REAL_USER" mkdir -p "$SYSTEMD_DIR"

    # Cari absolute path dari Wine secara dinamis agar kompatibel dengan berbagai distro
    local WINE_PATH
    WINE_PATH=$(sudo -u "$REAL_USER" which wine || echo "/usr/bin/wine")
    info "Wine ditemukan pada: $WINE_PATH"

    # Buat file bps.service
    # Menggunakan Systemd memecahkan masalah gantung saat shutdown karena systemd akan menghentikan proses secara bersih
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=BPS Print Service
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/bps-print-service
Environment=DISPLAY=:0
ExecStart=$WINE_PATH BPS.exe
Restart=always
RestartSec=5
StandardOutput=append:/tmp/bps.log
StandardError=append:/tmp/bps.log

[Install]
WantedBy=default.target
EOF

    # Sesuaikan kepemilikan file service
    chown "$REAL_USER:$REAL_USER" "$SERVICE_FILE"

    # Aktifkan service di lingkungan systemd user
    info "Mengaktifkan service bps.service di systemd..."
    sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$USER_ID" systemctl --user daemon-reload
    sudo -u "$REAL_USER" env XDG_RUNTIME_DIR="/run/user/$USER_ID" systemctl --user enable bps.service

    # Membuat executable global di /usr/local/bin/bps-run sebagai manager service
    info "Membuat perintah global 'bps-run' di /usr/local/bin..."
    
    cat << 'EOF' > /usr/local/bin/bps-run
#!/usr/bin/env bash
# =============================================================================
# BPS Print Service Manager
# =============================================================================

if [[ $EUID -eq 0 ]]; then
    echo "[ERROR] Jangan jalankan bps-run dengan sudo!" >&2
    echo "        Cukup jalankan sebagai user biasa: bps-run [start|stop|restart|status|log]" >&2
    exit 1
fi

ACTION="${1:-restart}"

case "$ACTION" in
    start)
        systemctl --user start bps.service
        echo "[INFO] Layanan BPS Print Service berhasil dijalankan."
        ;;
    stop)
        systemctl --user stop bps.service
        echo "[INFO] Layanan BPS Print Service berhasil dihentikan."
        ;;
    restart)
        systemctl --user restart bps.service
        echo "[INFO] Layanan BPS Print Service berhasil dimuat ulang (restarted)."
        ;;
    status)
        systemctl --user status bps.service
        ;;
    log)
        echo "[INFO] Menampilkan log aktivitas (tekan Ctrl+C untuk keluar):"
        tail -f /tmp/bps.log
        ;;
    *)
        echo "Penggunaan: bps-run [start|stop|restart|status|log]"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/bps-run
    info "Perintah global 'bps-run' berhasil dibuat."
}

# 6. Inisialisasi Prefiks Wine sebagai User Biasa
init_wine_prefix() {
    REAL_USER="$SUDO_USER"
    info "Melakukan inisialisasi Wine Prefix untuk user '${REAL_USER}' agar berjalan lancar..."
    sudo -u "$REAL_USER" env DISPLAY=:0 wineboot --init
}

print_summary() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    APP_DIR="$USER_HOME/bps-print-service"
    LOG_FILE="/tmp/bps.log"

    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    info "Instalasi Selesai dengan Sukses (Wine 9.0+ WineHQ)!"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    echo "  Folder Aplikasi   :  $APP_DIR"
    echo "  Berkas Log        :  $LOG_FILE"
    echo "  Autostart Setup   :  Aktif via Systemd User Service (Otomatis jalan saat login/boot)"
    echo "  Font Microsoft    :  Dilewati (Silakan instal ttf-mscorefonts-installer manual jika font kotak-kotak)"
    echo ""
    echo "  Layanan printer Anda sekarang siap digunakan."
    echo "  Anda bisa langsung mengetik perintah berikut di terminal ini:"
    echo ""
    echo -e "    ${YELLOW}bps-run start${NC}   <- Menjalankan layanan"
    echo -e "    ${YELLOW}bps-run stop${NC}    <- Menghentikan layanan"
    echo -e "    ${YELLOW}bps-run status${NC}  <- Memeriksa status layanan"
    echo -e "    ${YELLOW}bps-run log${NC}     <- Melihat log aktivitas"
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
}

main() {
    check_root
    detect_distro
    install_dependencies
    download_app
    setup_systemd_service
    init_wine_prefix
    print_summary
}

main "$@"