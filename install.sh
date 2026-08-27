#!/usr/bin/env bash
# ==============================================================================
# BPS Oneliner-Script: Automated Installer (Version 2)
# Resolves: Sudo $HOME pathing issue, hidden directories (.local), Wine absolute
# path bugs, and explicitly forces DISPLAY=:0 for GUI/GDI+ rendering.
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
        echo "  Gunakan perintah: sudo ./install.sh"
        exit 1
    fi
    if [[ -z "${SUDO_USER:-}" ]]; then
        error "Mohon jalankan skrip ini menggunakan 'sudo ./install.sh', bukan langsung login sebagai root."
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

# 3. Instal Wine dan dependensi yang sesuai untuk distro target
install_wine() {
    info "Memulai instalasi Wine dan dependensi pendukung..."
    
    # Deteksi Fedora
    if [[ "$DISTRO_ID" == "fedora" ]]; then
        info "Menjalankan instalasi paket untuk Fedora..."
        dnf install -y wine wine-mono mingw32-wine-gecko mingw64-wine-gecko
        
    # Deteksi Debian / Ubuntu / Linux Mint / Pop!_OS
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        info "Menjalankan instalasi paket untuk Debian/Ubuntu......"
        apt-get update
        apt-get install -y wine wine-mono wine-gecko
        
        # Opsional: Instal fonts Microsoft jika tersedia di sistem
        if apt-cache show ttf-mscorefonts-installer &>/dev/null; then
            info "Menginstal ttf-mscorefonts-installer untuk menghindari huruf kotak-kotak..."
            echo ttf-mscorefonts-installer msttcorefontshandler/accepted-mscorefonts-eula select true | debconf-set-selections || true
            apt-get install -y ttf-mscorefonts-installer || warn "Gagal menginstal font Microsoft Core Fonts, instalasi BPS akan tetap dilanjutkan."
        fi

    # Deteksi Arch Linux / Manjaro
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        info "Menjalankan instalasi paket untuk Arch Linux..."
        pacman -Syu --noconfirm wine wine-mono wine-gecko

    else
        warn "Distribusi Linux Anda (${DISTRO_ID}) tidak terdaftar secara resmi."
        warn "Pastikan 'wine', 'wine-mono', dan 'wine-gecko' sudah terpasang secara manual."
        read -p "Apakah Anda ingin tetap melanjutkan instalasi? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Instalasi dibatalkan oleh pengguna."
            exit 1
        fi
    fi
    
    info "Wine dan dependensi pendukung berhasil dikonfigurasi."
}

# 4. Pengaturan Direktori dan Penyalinan Berkas BPS
setup_app() {
    # Dapatkan HOME directory asli milik user non-root yang memanggil sudo
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    APP_NAME="BPS Print Service"
    APP_DIR="$USER_HOME/BPS" # SANGAT AMAN: Menggunakan folder ~/BPS yang sudah terbukti sukses!
    BIN_DIR="$USER_HOME/.local/bin"
    AUTOSTART_DIR="$USER_HOME/.config/autostart"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LOG_FILE="/tmp/bps.log"

    info "Mengonfigurasi direktori aplikasi untuk user: ${REAL_USER}"
    info "Target folder aplikasi: ${APP_DIR}"

    # Buat direktori dengan permission milik user asli
    sudo -u "$REAL_USER" mkdir -p "$APP_DIR" "$BIN_DIR" "$AUTOSTART_DIR"

    # Periksa ketersediaan berkas utama
    if [[ ! -f "$SCRIPT_DIR/BPS.exe" ]]; then
        error "Berkas 'BPS.exe' tidak ditemukan di folder repositori: $SCRIPT_DIR"
        error "Silakan pastikan berkas BPS.exe sudah terunduh sebelum menjalankan skrip."
        exit 1
    fi

    # Salin berkas BPS dan konfigurasi
    info "Menyalin berkas aplikasi..."
    cp "$SCRIPT_DIR/BPS.exe" "$APP_DIR/"
    if [[ -f "$SCRIPT_DIR/appsettings.json" ]]; then
        cp "$SCRIPT_DIR/appsettings.json" "$APP_DIR/"
    else
        warn "File 'appsettings.json' tidak ditemukan di folder instalasi. Menggunakan pengaturan bawaan aplikasi."
    fi

    # Atur kepemilikan agar menjadi milik user biasa (bukan root)
    chown -R "$REAL_USER:$REAL_USER" "$APP_DIR"

    # Buat launcher script 'bps-run'
    info "Membuat berkas peluncur (launcher) di ${BIN_DIR}/bps-run..."
    cat << 'EOF' > "$BIN_DIR/bps-run"
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/BPS"
LOG_FILE="/tmp/bps.log"
BPS_EXE="$APP_DIR/BPS.exe"

if [[ ! -f "$BPS_EXE" ]]; then
    echo "[ERROR] BPS.exe tidak ditemukan di: $BPS_EXE" >&2
    echo "        Silakan jalankan ulang install.sh" >&2
    exit 1
fi

if ! command -v wine &>/dev/null; then
    echo "[ERROR] Wine belum terinstal di sistem ini." >&2
    echo "        Silakan jalankan: sudo ./install.sh" >&2
    exit 1
fi

# Hentikan BPS yang mungkin sedang berjalan sebelumnya
pkill -f BPS.exe 2>/dev/null || true
sleep 1

# =====================================================================
# METODE PEMULIHAN UTUH & TERBUKTI:
# 1. Berpindah langsung ke direktori ~/BPS sebelum memanggil wine
# 2. Mengatur DISPLAY=:0 secara eksplisit sebelum menjalankan wine
# 3. Memanggil file lokal 'BPS.exe' alih-alih absolute path agar tidak
#    terjadi error 'ShellExecuteEx failed: File not found'
# =====================================================================
cd "$APP_DIR"

export DISPLAY=:0
nohup wine BPS.exe > "$LOG_FILE" 2>&1 &
BPS_PID=$!

# Tunggu sebentar untuk memastikan aplikasi tidak langsung crash
sleep 2
if kill -0 "$BPS_PID" 2>/dev/null; then
    echo "[INFO] BPS Print Service berhasil dijalankan (PID: $BPS_PID)"
    echo "[INFO] File log aktivitas dapat dipantau di: $LOG_FILE"
else
    echo "[ERROR] BPS Print Service gagal berjalan saat startup." >&2
    echo "        Lihat detail error pada berkas log: $LOG_FILE" >&2
    tail -n 20 "$LOG_FILE" >&2
    exit 1
fi
EOF

    # Atur permission executable dan kepemilikan launcher
    chmod +x "$BIN_DIR/bps-run"
    chown "$REAL_USER:$REAL_USER" "$BIN_DIR/bps-run"
}

# 5. Inisialisasi Prefiks Wine sebagai User Biasa
init_wine_prefix() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    info "Melakukan inisialisasi Wine Prefix untuk user '${REAL_USER}' agar berjalan lancar..."
    # Jalankan wineboot sebagai user biasa demi menghindari file prefiks dimiliki root
    sudo -u "$REAL_USER" env DISPLAY=:0 wineboot --init
}

# 6. Mengonfigurasi Autostart saat User Login
setup_autostart() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    BIN_DIR="$USER_HOME/.local/bin"
    AUTOSTART_DIR="$USER_HOME/.config/autostart"

    info "Membuat konfigurasi autostart agar BPS berjalan otomatis saat login..."
    
    cat << EOF > "$AUTOSTART_DIR/bps-print-service.desktop"
[Desktop Entry]
Type=Application
Name=BPS Print Service
Comment=BGEN Print Service Automation
Exec=$BIN_DIR/bps-run
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

    # Atur kepemilikan dan permission autostart file
    chown "$REAL_USER:$REAL_USER" "$AUTOSTART_DIR/bps-print-service.desktop"
    chmod +x "$AUTOSTART_DIR/bps-print-service.desktop"
}

# 7. Tampilkan Ringkasan Hasil Instalasi
print_summary() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    APP_DIR="$USER_HOME/BPS"
    BIN_DIR="$USER_HOME/.local/bin"
    AUTOSTART_DIR="$USER_HOME/.config/autostart"
    LOG_FILE="/tmp/bps.log"

    echo ""
    echo -e "${GREEN}=======================================================${NC}\"\n"
    info "Instalasi ${APP_NAME} Selesai!"
    echo -e "${GREEN}=======================================================${NC}\"\n"
    echo ""
    echo "  Folder Instalasi :  $APP_DIR"
    echo "  File Launcher     :  $BIN_DIR/bps-run"
    echo "  Berkas Log        :  $LOG_FILE"
    echo "  Berkas Autostart  :  $AUTOSTART_DIR/bps-print-service.desktop"
    echo ""
    echo "  Cara Mengelola Layanan BPS:"
    echo -e "  - ${YELLOW}Menjalankan Sekarang${NC}   : bps-run"
    echo -e "  - ${YELLOW}Menghentikan Layanan${NC}  : pkill -f BPS.exe"
    echo -e "  - ${YELLOW}Menghapus (Uninstall)${NC}: sudo ./uninstall.sh"
    echo ""
    echo -e "  ${YELLOW}CATATAN PENTING:${NC}"
    echo "  Pastikan Anda telah mendaftarkan Printer Anda di CUPS Linux Anda,"
    echo "  lalu sesuaikan nama printer tersebut di file konfigurasi:"
    echo "  -> $APP_DIR/appsettings.json"
    echo -e "${GREEN}=======================================================${NC}\"\n"
}

main() {
    check_root
    detect_distro
    install_wine
    setup_app
    init_wine_prefix
    setup_autostart
    print_summary
}

main "$@"
