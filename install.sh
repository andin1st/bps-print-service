#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BPS Print Service"
APP_DIR="$HOME/.local/share/bps"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/bps.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run with sudo"
        echo "  Usage: sudo ./install.sh"
        exit 1
    fi
    if [[ -z "${SUDO_USER:-}" ]]; then
        error "Please run via sudo, not as root directly"
        exit 1
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
    fi

    if command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
    elif command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    elif command -v zypper &>/dev/null; then
        PKG_MGR="zypper"
    else
        error "Unsupported package manager. Install wine, wine-mono, and wine-gecko manually."
        exit 1
    fi

    info "Detected distro: $DISTRO_ID (package manager: $PKG_MGR)"
}

install_wine() {
    info "Installing Wine and dependencies..."

    case "$PKG_MGR" in
        pacman)
            pacman -S --needed --noconfirm wine wine-mono wine-gecko
            ;;
        apt)
            apt-get update -qq
            apt-get install -y -qq wine wine-mono wine-gecko
            ;;
        dnf)
            dnf install -y wine wine-mono wine-gecko
            ;;
        zypper)
            zypper install -y wine wine-mono wine-gecko
            ;;
    esac

    if ! command -v wine &>/dev/null; then
        error "Wine installation failed. Please install manually:"
        echo "  Debian/Ubuntu: sudo apt install wine wine-mono wine-gecko"
        echo "  Fedora:        sudo dnf install wine wine-mono wine-gecko"
        echo "  Arch:          sudo pacman -S wine wine-mono wine-gecko"
        exit 1
    fi

    info "Wine $(wine --version) installed successfully"
}

setup_app() {
    info "Setting up $APP_NAME..."

    sudo -u "$SUDO_USER" mkdir -p "$APP_DIR"
    sudo -u "$SUDO_USER" mkdir -p "$BIN_DIR"

    sudo -u "$SUDO_USER" cp "$SCRIPT_DIR/BPS.exe" "$APP_DIR/"
    if [[ -f "$SCRIPT_DIR/appsettings.json" ]] && [[ ! -f "$APP_DIR/appsettings.json" ]]; then
        sudo -u "$SUDO_USER" cp "$SCRIPT_DIR/appsettings.json" "$APP_DIR/"
    fi

    sudo -u "$SUDO_USER" cp "$SCRIPT_DIR/run.sh" "$BIN_DIR/bps-run"
    chmod +x "$BIN_DIR/bps-run"

    sudo -u "$SUDO_USER" mkdir -p "$APP_DIR/logs"

    info "Application installed to $APP_DIR"
}

init_wine_prefix() {
    local WINE_PREFIX
    WINE_PREFIX=$(sudo -u "$SUDO_USER" bash -c 'echo $WINE_PREFIX')
    WINE_PREFIX="${WINE_PREFIX:-$HOME/.wine}"

    if [[ ! -d "$WINE_PREFIX" ]]; then
        info "Initializing Wine prefix (first time only)..."
        sudo -u "$SUDO_USER" wineboot --init 2>/dev/null || true
        info "Wine prefix initialized at $WINE_PREFIX"
    else
        info "Wine prefix already exists at $WINE_PREFIX"
    fi
}

setup_autostart() {
    info "Setting up autostart..."

    sudo -u "$SUDO_USER" mkdir -p "$AUTOSTART_DIR"

    sudo -u "$SUDO_USER" cat > "$AUTOSTART_DIR/bps-print-service.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=BGEN Print Service
Exec=$BIN_DIR/bps-run
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

    info "Autostart entry created at $AUTOSTART_DIR/bps-print-service.desktop"
}

print_summary() {
    echo ""
    echo "============================================"
    info "$APP_NAME installed successfully!"
    echo "============================================"
    echo ""
    echo "  Install dir:   $APP_DIR"
    echo "  Launcher:      $BIN_DIR/bps-run"
    echo "  Log file:      $LOG_FILE"
    echo "  Autostart:     $AUTOSTART_DIR/bps-print-service.desktop"
    echo ""
    echo "  To run now:    $BIN_DIR/bps-run"
    echo "  To stop:       pkill -f BPS.exe"
    echo "  To uninstall:  sudo ./uninstall.sh"
    echo ""
    echo "  NOTE: Configure printer in $APP_DIR/appsettings.json"
    echo "============================================"
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
