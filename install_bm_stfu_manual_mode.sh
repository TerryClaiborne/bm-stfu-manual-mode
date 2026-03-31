#!/bin/bash
set -euo pipefail

# Manual STFU installer for ASL3 / DVSwitch systems
# This script:
# - installs the STFU binary for aarch64 systems
# - creates the required DVSwitch.ini symlink in /opt/STFU
# - installs bm-stfu.sh into /usr/local/bin
#
# After running this script, you MUST still edit:
#   /opt/MMDVM_Bridge/DVSwitch.ini
# and set the [STFU] section with your real BM password, DMR ID,
# TalkerAlias, and StartTG.

REPO_DIR="/opt/STFU"
STFU_BIN_TARGET="/usr/local/bin/STFU"
SCRIPT_TARGET="/usr/local/bin/bm-stfu.sh"
DVSWITCH_INI="/opt/MMDVM_Bridge/DVSwitch.ini"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: Run this script as root with sudo."
    exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
    echo "ERROR: This installer is written for aarch64 systems."
    echo "Update it manually if your system uses a different architecture."
    exit 1
fi

if [[ ! -f "$DVSWITCH_INI" ]]; then
    echo "ERROR: DVSwitch.ini not found at $DVSWITCH_INI"
    exit 1
fi

echo "Installing git if needed..."
apt update
apt install -y git

if [[ ! -d "$REPO_DIR" ]]; then
    echo "Cloning STFU repo into $REPO_DIR ..."
    git clone https://github.com/DVSwitch/STFU.git "$REPO_DIR"
else
    echo "STFU repo already exists at $REPO_DIR"
fi

if [[ ! -f "$REPO_DIR/bin/STFU.arm64" ]]; then
    echo "ERROR: Expected binary not found: $REPO_DIR/bin/STFU.arm64"
    exit 1
fi

echo "Installing STFU binary..."
cp "$REPO_DIR/bin/STFU.arm64" "$STFU_BIN_TARGET"
chmod +x "$STFU_BIN_TARGET"

echo "Creating /opt/STFU/DVSwitch.ini symlink..."
ln -sf "$DVSWITCH_INI" "$REPO_DIR/DVSwitch.ini"

cat > "$SCRIPT_TARGET" <<'SCRIPT_EOF'
#!/bin/bash
set -euo pipefail

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

is_stfu_running() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

ensure_symlink() {
    mkdir -p "$STFU_DIR"
    ln -sf "$DVSWITCH_INI" "$STFU_DIR/DVSwitch.ini"
}

connect_dvswitch_node() {
    sudo /usr/sbin/asterisk -rx "rpt fun ${MAIN_NODE} *3${DVSWITCH_NODE}" >/dev/null
}

disconnect_dvswitch_node() {
    sudo /usr/sbin/asterisk -rx "rpt fun ${MAIN_NODE} *1${DVSWITCH_NODE}" >/dev/null || true
}

start_stfu_process() {
    if is_stfu_running; then
        echo "STFU is already running."
        return
    fi

    ensure_symlink
    mkdir -p "$(dirname "$LOG_FILE")"

    cd "$STFU_DIR"
    nohup sudo "$STFU_BIN" >>"$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    sleep 2

    if ! kill -0 "$pid" 2>/dev/null; then
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
    fi
}

start_mode() {
    local tg="${1:-}"

    if [[ -z "$tg" ]]; then
        echo "ERROR: You must supply a BM talkgroup."
        echo "Example: bm-stfu.sh start 3220008"
        exit 1
    fi

    require_file "$STFU_BIN"
    require_file "$DVSWITCH_SH"
    require_file "$DVSWITCH_INI"

    echo "Stopping mmdvm_bridge..."
    sudo systemctl stop mmdvm_bridge

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
    echo "Use: bm-stfu.sh tune <tg>   to change talkgroups"
    echo "Use: bm-stfu.sh stop        to return to normal mode"
}

tune_mode() {
    local tg="${1:-}"

    if [[ -z "$tg" ]]; then
        echo "ERROR: You must supply a BM talkgroup."
        echo "Example: bm-stfu.sh tune 91"
        exit 1
    fi

    require_file "$DVSWITCH_SH"

    if ! is_stfu_running; then
        echo "ERROR: STFU is not running."
        echo "Start it first with: bm-stfu.sh start <talkgroup>"
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
    sudo systemctl start mmdvm_bridge

    echo "Returned to normal MMDVM_Bridge mode."
}

status_mode() {
    if is_stfu_running; then
        echo "STFU is running. PID: $(cat "$PID_FILE")"
    else
        echo "STFU is not running."
    fi

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
        echo "  bm-stfu.sh start <talkgroup>"
        echo "  bm-stfu.sh tune <talkgroup>"
        echo "  bm-stfu.sh stop"
        echo "  bm-stfu.sh status"
        exit 1
        ;;
esac
SCRIPT_EOF

chmod +x "$SCRIPT_TARGET"

echo
echo "Install complete."
echo
echo "Next required manual steps:"
echo "1) Edit /opt/MMDVM_Bridge/DVSwitch.ini"
echo "2) Set the [STFU] section with your real BMPassword, UserID, TalkerAlias, and StartTG"
echo "3) Edit /usr/local/bin/bm-stfu.sh if your MAIN_NODE or DVSWITCH_NODE are different"
echo
echo "Quick test commands:"
echo "  bm-stfu.sh status"
echo "  bm-stfu.sh start 3220008"
echo "  bm-stfu.sh tune 91"
echo "  bm-stfu.sh stop"
