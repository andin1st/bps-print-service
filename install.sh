#!/usr/bin/env bash
# =============================================================================
# BPS Oneliner-Script: Automated Installer (Version 4)
# Features: 
#   1. Automatic distro detection & Wine installation
#   2. Installs a global /usr/local/bin/bps-run wrapper for INSTANT execution
#   3. Adds shell alias fallback in .bashrc and .zshrc
# No "source ~/.bashrc" required! Works instantly after installation.
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
    
    if [[ "$DISTRO_ID" == "fedora" ]]; then
        info "Menjalankan instalasi paket untuk Fedora..."
        dnf install -y wine wine-mono mingw32-wine-gecko mingw64-wine-gecko
        
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        info "Menjalankan instalasi paket untuk Debian/Ubuntu..."
        apt-get update
        apt-get install -y wine wine-mono wine-gecko
        
        if apt-cache show ttf-mscorefonts-installer &>/dev/null; then
            info "Menginstal ttf-mscorefonts-installer..."
            echo ttf-mscorefonts-installer msttcorefontshandler/accepted-mscorefonts-eula select true | debconf-set-selections || true
            apt-get install -y ttf-mscorefonts-installer || warn "Gagal menginstal font Microsoft Core Fonts."
        fi

    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        info "Menjalankan instalasi paket untuk Arch Linux..."
        pacman -Syu --noconfirm wine wine-mono wine-gecko

    else
        warn "Distribusi Linux Anda (${DISTRO_ID}) tidak terdaftar secara resmi."
        warn "Pastikan 'wine', 'wine-mono', dan 'wine-gecko' sudah terpasang."
    fi
    
    info "Wine dan dependensi pendukung berhasil dikonfigurasi."
}

# 4. Buat Perintah Global & Konfigurasi Alias
setup_shortcuts() {
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    # -------------------------------------------------------------------------
    # SOLUSI INSTAN TANPA PERLU 'source ~/.bashrc' ATAU BUKA TERMINAL BARU:
    # Kita membuat file executable di /usr/local/bin/bps-run.
    # Karena /usr/local/bin selalu ada di $PATH sistem, perintah 'bps-run'
    # bisa langsung dipanggil KETIKA ITU JUGA di terminal aktif setelah install.
    # -------------------------------------------------------------------------
    info "Membuat perintah global 'bps-run' di /usr/local/bin..."
    
    cat << EOF > /usr/local/bin/bps-run
#!/usr/bin/env bash
# Jalankan menggunakan profil user asli agar konfigurasi Wine terisolasi dengan benar
cd "$USER_HOME/bps-print-service" && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &
EOF

    chmod +x /usr/local/bin/bps-run
    info "Perintah global 'bps-run' berhasil dibuat."

    # -------------------------------------------------------------------------
    # BACKUP ALIAS (Opsional untuk integrasi shell .bashrc / .zshrc)
    # -------------------------------------------------------------------------
    info "Mendaftarkan alias cadangan ke berkas konfigurasi shell..."
    ALIAS_CMD="alias bps-run=\"cd \$HOME/bps-print-service && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &\""
    
    # Daftarkan ke .bashrc jika ada
    if [[ -f "$USER_HOME/.bashrc" ]]; then
        if ! grep -q "alias bps-run=" "$USER_HOME/.bashrc"; then
            echo "$ALIAS_CMD" >> "$USER_HOME/.bashrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc"
            info "Alias ditambahkan ke $USER_HOME/.bashrc"
        fi
    fi

    # Daftarkan ke .zshrc jika ada
    if [[ -f "$USER_HOME/.zshrc" ]]; then
        if ! grep -q "alias bps-run=" "$USER_HOME/.zshrc"; then
            echo "$ALIAS_CMD" >> "$USER_HOME/.zshrc"
            chown "$REAL_USER:$REAL_USER" "$USER_HOME/.zshrc"
            info "Alias ditambahkan ke $USER_HOME/.zshrc"
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    info "Instalasi Selesai dengan Sukses!"
    echo -e "${GREEN}=======================================================${NC}"
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
    install_wine
    setup_shortcuts
    print_summary
}

main "$@"
