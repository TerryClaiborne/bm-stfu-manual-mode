#!/bin/bash
set -euo pipefail

# Edit these two values for your system
MAIN_NODE="67040"
DVSWITCH_NODE="1957"

STFU_DIR="/opt/STFU"
STFU_BIN="/usr/local/bin/STFU"
DVSWITCH_SH="/opt/MMDVM_Bridge/dvswitch.sh"
DVSWITCH_INI="/opt/MMDVM_Bridge/DVSwitch.ini"

PID_FILE="/var/run/bm-stfu.pid"
LOG_FILE="/var/log/bm-stfu.log"

require_file() {
    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo "ERROR: Required file not found: $file"
        exit 1
    fi
}

ensure_symlink() {
    mkdir -p "$STFU_DIR"
    ln -sf "$DVSWITCH_INI" "$STFU_DIR/DVSwitch.ini"
}

is_stfu_running() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

connect_dvswitch_node() {
    /usr/sbin/asterisk -rx "rpt fun ${MAIN_NODE} *3${DVSWITCH_NODE}" >/dev/null
}

disconnect_dvswitch_node() {
    /usr/sbin/asterisk -rx "rpt fun ${MAIN_NODE} *1${DVSWITCH_NODE}" >/dev/null || true
}

start_stfu_process() {
    if is_stfu_running; then
        echo "STFU is already running."
        return
    fi

    ensure_symlink
    touch "$LOG_FILE"

    (
        cd "$STFU_DIR"
        nohup "$STFU_BIN" >>"$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
    )

    sleep 2

    if ! is_stfu_running; then
        echo "ERROR: STFU failed to start. Check $LOG_FILE"
        rm -f "$PID_FILE"
        exit 1
    fi
}

stop_stfu_process() {
    if is_stfu_running; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        sleep 1
        kill -9 "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    else
        rm -f "$PID_FILE"
        pkill -f "^${STFU_BIN}$" 2>/dev/null || true
    fi
}

start_mode() {
    local tg="${1:-}"

    if [[ -z "$tg" ]]; then
        echo "ERROR: You must supply a BM talkgroup."
        echo "Example: sudo bm-stfu.sh start 3220008"
        exit 1
    fi

    require_file "$STFU_BIN"
    require_file "$DVSWITCH_SH"
    require_file "$DVSWITCH_INI"

    echo "Stopping mmdvm_bridge..."
    systemctl stop mmdvm_bridge

    echo "Connecting DVSwitch node ${DVSWITCH_NODE} from ${MAIN_NODE}..."
    connect_dvswitch_node
    sleep 1

    echo "Switching DVSwitch to STFU mode..."
    "$DVSWITCH_SH" mode STFU
    sleep 1

    echo "Starting STFU..."
    start_stfu_process

    echo "Tuning BM talkgroup ${tg}..."
    "$DVSWITCH_SH" tune "$tg"

    echo "STFU BM mode started on TG ${tg}."
    echo "Use: sudo bm-stfu.sh tune <talkgroup>"
    echo "Use: sudo bm-stfu.sh stop"
}

tune_mode() {
    local tg="${1:-}"

    if [[ -z "$tg" ]]; then
        echo "ERROR: You must supply a BM talkgroup."
        echo "Example: sudo bm-stfu.sh tune 91"
        exit 1
    fi

    require_file "$DVSWITCH_SH"

    if ! is_stfu_running; then
        echo "ERROR: STFU is not running."
        echo "Start it first with: sudo bm-stfu.sh start <talkgroup>"
        exit 1
    fi

    echo "Tuning BM talkgroup ${tg}..."
    "$DVSWITCH_SH" tune "$tg"
    echo "Tuned to TG ${tg}."
}

stop_mode() {
    echo "Stopping STFU..."
    stop_stfu_process

    echo "Disconnecting DVSwitch node ${DVSWITCH_NODE}..."
    disconnect_dvswitch_node

    echo "Starting mmdvm_bridge..."
    systemctl start mmdvm_bridge

    echo "Returned to normal MMDVM_Bridge mode."
}

status_mode() {
    if is_stfu_running; then
        echo "STFU is running. PID: $(cat "$PID_FILE")"
    else
        echo "STFU is not running."
    fi

    echo -n "mmdvm_bridge: "
    systemctl is-active mmdvm_bridge || true
}

case "${1:-}" in
    start)
        start_mode "${2:-}"
        ;;
    tune)
        tune_mode "${2:-}"
        ;;
    stop)
        stop_mode
        ;;
    status)
        status_mode
        ;;
    *)
        echo "Usage:"
        echo "  sudo bm-stfu.sh start <talkgroup>"
        echo "  sudo bm-stfu.sh tune <talkgroup>"
        echo "  sudo bm-stfu.sh stop"
        echo "  sudo bm-stfu.sh status"
        exit 1
        ;;
esac
