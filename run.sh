#!/usr/bin/env bash
# ==============================================================================
# BPS Oneliner-Script Launcher (Version 2)
# Resolves: Wine absolute path translation errors and Kestrel path requirements
# by executing directly from the application's home directory.
# ==============================================================================

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
