#!/usr/bin/env bash
# =============================================================================
# BPS Oneliner-Script: Automated Installer (Version 6 - Ultimate with Autostart)
# Features: 
#   1. Automatic distro detection & Wine installation (Fedora, Debian, Ubuntu, Arch)
#   2. Downloads BPS.exe and appsettings.json from GitHub using curl (No Git needed!)
#   3. Installs a global /usr/local/bin/bps-run wrapper for INSTANT execution
#   4. Sets up Desktop Autostart so the service runs automatically on boot/login!
#   5. Adds shell alias fallback in .bashrc and .zshrc
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
        error "Silakan buat Release baru di https://github.com/andin1st/bps-print-service/releases and unggah BPS.exe di sana."
        rm -f "$APP_DIR/BPS.exe"
        exit 1
    fi

    # Atur kepemilikan agar menjadi milik user biasa (bukan root)
    chown -R "$REAL_USER:$REAL_USER" "$APP_DIR"
    chmod +x "$APP_DIR/BPS.exe"
}

# 5. Buat Perintah Global & Konfigurasi Alias
setup_shortcuts() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    # Membuat executable global di /usr/local/bin/bps-run
    info "Membuat perintah global 'bps-run' di /usr/local/bin..."
    
    cat << EOF > /usr/local/bin/bps-run
#!/usr/bin/env bash
# Jalankan menggunakan profil user asli agar konfigurasi Wine terisolasi dengan benar
cd "$USER_HOME/bps-print-service" && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &
EOF

    chmod +x /usr/local/bin/bps-run
    info "Perintah global 'bps-run' berhasil dibuat."

    # BACKUP ALIAS (Opsional untuk integrasi shell .bashrc / .zshrc)
    info "Mendaftarkan alias cadangan ke berkas konfigurasi shell..."
    ALIAS_CMD="alias bps-run=\"cd \$HOME/bps-print-service && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &\""
    
    # Daftarkan ke .bashrc jika ada
    if [[ -f "$USER_HOME/.bashrc" ]]; then
        if ! grep -q "alias bps-run=" "$USER_HOME/.bashrc"; then
            echo -e "\n# BPS Print Service Alias\n$ALIAS_CMD" >> "$USER_HOME/.bashrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc"
            info "Alias ditambahkan ke $USER_HOME/.bashrc"
        fi
    fi

    # Daftarkan ke .zshrc jika ada
    if [[ -f "$USER_HOME/.zshrc" ]]; then
        if ! grep -q "alias bps-run=" "$USER_HOME/.zshrc"; then
            echo -e "\n# BPS Print Service Alias\n$ALIAS_CMD" >> "$USER_HOME/.zshrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.zshrc"
            info "Alias ditambahkan ke $USER_HOME/.zshrc"
        fi
    fi
}

# 6. Mengonfigurasi Autostart saat User Login ke Desktop
setup_autostart() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    AUTOSTART_DIR="$USER_HOME/.config/autostart"
    
    info "Membuat konfigurasi autostart agar BPS berjalan otomatis saat komputer menyala (login)..."
    
    # Buat direktori jika belum ada
    sudo -u "$REAL_USER" mkdir -p "$AUTOSTART_DIR"
    
    # Buat file entri desktop autostart
    cat << EOF > "$AUTOSTART_DIR/bps-print-service.desktop"
[Desktop Entry]
Type=Application
Name=BPS Print Service
Comment=BGEN Print Service Automation
Exec=/usr/local/bin/bps-run
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

    # Atur kepemilikan dan permission agar aman dan bisa dieksekusi desktop environment
    chown "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR/bps-print-service.desktop"
    chmod +x "$AUTOSTART_DIR/bps-print-service.desktop"
    info "Autostart berhasil diatur di: $AUTOSTART_DIR/bps-print-service.desktop"
}

# 7. Inisialisasi Prefiks Wine sebagai User Biasa
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
    info "Instalasi Selesai dengan Sukses!"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    echo "  Folder Aplikasi   :  $APP_DIR"
    echo "  Berkas Log        :  $LOG_FILE"
    echo "  Autostart Setup   :  Aktif (Otomatis jalan saat komputer login)"
    echo ""
    echo "  Layanan printer Anda sekarang siap digunakan."
    echo "  Anda bisa langsung mengetik perintah berikut di terminal ini:"
    echo ""
    echo -e "    ${YELLOW}bps-run${NC}"
    echo ""
    echo "  (Tanpa perlu melakukan 'source ~/.bashrc' atau membuka terminal baru!)"
    echo -e "${GREEN}=======================================================${NC}"
}

main() {
    check_root
    detect_distro
    install_dependencies
    download_app
    setup_shortcuts
    setup_autostart
    init_wine_prefix
    print_summary
}

main "$@"