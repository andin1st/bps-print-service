#!/usr/bin/env bash
# ==============================================================================
# BPS Oneliner-Script: Automated Installer (Clean Rebuild)
# Detects distribution and appends the running alias directly to .bashrc/.zshrc
# ==============================================================================

set -euo pipefail

# ANSI Color Codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 1. Pastikan skrip dijalankan menggunakan sudo
if [[ $EUID -ne 0 ]]; then
    error "Skrip ini harus dijalankan dengan hak akses root (sudo)."
    echo "  Gunakan perintah: sudo ./install.sh"
    exit 1
fi

if [[ -z "${SUDO_USER:-}" ]]; then
    error "Mohon jalankan skrip ini menggunakan 'sudo ./install.sh', bukan langsung login sebagai root."
    exit 1
fi

# Dapatkan informasi pengguna non-root yang memicu sudo
REAL_USER="$SUDO_USER"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# 2. Deteksi OS dan Pasang Dependensi Wine yang Sesuai
detect_and_install() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
    fi

    info "Mendeteksi distribusi sistem operasi: ${DISTRO_ID}"

    # Deteksi Fedora
    if [[ "$DISTRO_ID" == "fedora" ]]; then
        info "Menjalankan instalasi paket untuk Fedora..."
        dnf install -y wine wine-mono mingw32-wine-gecko mingw64-wine-gecko
        
    # Deteksi Debian / Ubuntu / Linux Mint / Pop!_OS
    elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        info "Menjalankan instalasi paket untuk Debian/Ubuntu..."
        apt-get update
        apt-get install -y wine wine-mono wine-gecko

    # Deteksi Arch Linux / Manjaro
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        info "Menjalankan instalasi paket untuk Arch Linux..."
        pacman -Syu --noconfirm wine wine-mono wine-gecko

    else
        warn "Distribusi Linux Anda (${DISTRO_ID}) tidak didukung secara otomatis oleh installer."
        warn "Pastikan paket 'wine', 'wine-mono', dan 'wine-gecko' telah dipasang manual."
        read -p "Apakah Anda ingin tetap melanjutkan proses pembuatan alias? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Instalasi dibatalkan oleh pengguna."
            exit 1
        fi
    fi
    info "Seluruh dependensi Wine telah terkonfigurasi dengan sukses!"
}

# 3. Tambahkan alias bps-run ke .bashrc atau .zshrc milik pengguna asli
add_alias() {
    # Catatan: Sintaks alias di bash/zsh tidak boleh menggunakan spasi di sekitar tanda '='
    local alias_line='alias bps-run="DISPLAY=:0 nohup wine ~/bps-print-service/BPS.exe > /tmp/bps.log 2>&1 &"'
    local added=0

    info "Mengonfigurasi alias 'bps-run' untuk pengguna '${REAL_USER}'..."

    # Menambahkan ke .bashrc jika ada
    local bashrc="$REAL_HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        if ! grep -q "alias bps-run=" "$bashrc"; then
            echo "" >> "$bashrc"
            echo "# --- BPS Print Service Alias ---" >> "$bashrc"
            echo "$alias_line" >> "$bashrc"
            chown "$REAL_USER:$REAL_USER" "$bashrc"
            info "Alias berhasil ditambahkan ke: $bashrc"
            added=1
        else
            warn "Alias 'bps-run' sudah terdaftar di $bashrc"
        fi
    fi

    # Menambahkan ke .zshrc jika ada
    local zshrc="$REAL_HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        if ! grep -q "alias bps-run=" "$zshrc"; then
            echo "" >> "$zshrc"
            echo "# --- BPS Print Service Alias ---" >> "$zshrc"
            echo "$alias_line" >> "$zshrc"
            chown "$REAL_USER:$REAL_USER" "$zshrc"
            info "Alias berhasil ditambahkan ke: $zshrc"
            added=1
        else
            warn "Alias 'bps-run' sudah terdaftar di $zshrc"
        fi
    fi

    if [[ $added -eq 1 ]]; then
        echo ""
        info "Alias berhasil dikonfigurasi!"
        echo -e "  Silakan muat ulang shell Anda dengan menjalankan salah satu perintah berikut:"
        echo -e "  - Untuk Bash : ${YELLOW}source ~/.bashrc${NC}"
        echo -e "  - Untuk Zsh  : ${YELLOW}source ~/.zshrc${NC}"
        echo ""
    fi
}

main() {
    detect_and_install
    add_alias
    info "Proses instalasi selesai sepenuhnya! Selamat menggunakan BPS Print Service."
}

main "$@"
