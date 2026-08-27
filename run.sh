#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/.local/share/bps"
LOG_FILE="/tmp/bps.log"
BPS_EXE="$APP_DIR/BPS.exe"

if [[ ! -f "$BPS_EXE" ]]; then
    echo "[ERROR] BPS.exe not found at $BPS_EXE" >&2
    echo "  Run install.sh first" >&2
    exit 1
fi

if ! command -v wine &>/dev/null; then
    echo "[ERROR] Wine is not installed" >&2
    echo "  Run: sudo ./install.sh" >&2
    exit 1
fi

pkill -f BPS.exe 2>/dev/null || true
sleep 1

export DISPLAY="${DISPLAY:-:0}"
nohup wine "$BPS_EXE" > "$LOG_FILE" 2>&1 &
BPS_PID=$!

sleep 2
if kill -0 "$BPS_PID" 2>/dev/null; then
    echo "[INFO] BPS Print Service started (PID: $BPS_PID)"
    echo "[INFO] Log: $LOG_FILE"
else
    echo "[ERROR] BPS failed to start. Check log: $LOG_FILE" >&2
    tail -20 "$LOG_FILE" >&2
    exit 1
fi
