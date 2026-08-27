#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BPS Print Service"
APP_DIR="$HOME/.local/share/bps"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ $EUID -ne 0 ]]; then
    error "This script must be run with sudo"
    echo "  Usage: sudo ./uninstall.sh"
    exit 1
fi

if [[ -z "${SUDO_USER:-}" ]]; then
    error "Please run via sudo, not as root directly"
    exit 1
fi

echo "This will remove $APP_NAME from your system."
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Uninstall cancelled."
    exit 0
fi

info "Stopping BPS if running..."
pkill -f BPS.exe 2>/dev/null || true

info "Removing autostart entry..."
rm -f "$AUTOSTART_DIR/bps-print-service.desktop"

info "Removing launcher..."
rm -f "$BIN_DIR/bps-run"

info "Removing application files..."
rm -rf "$APP_DIR"

info "$APP_NAME has been uninstalled."
echo ""
echo "  Wine is still installed. To remove it:"
echo "    Arch:    sudo pacman -Rns wine wine-mono wine-gecko"
echo "    Debian:  sudo apt remove wine wine-mono wine-gecko"
echo "    Fedora:  sudo dnf remove wine wine-mono wine-gecko"
