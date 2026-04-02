#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STFU_REPO_DIR="/opt/STFU"
STFU_BIN_TARGET="/usr/local/bin/STFU"
BM_STFU_TARGET="/usr/local/bin/bm-stfu.sh"
DVSWITCH_INI="/opt/MMDVM_Bridge/DVSwitch.ini"

need_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: Run this installer with sudo."
        exit 1
    fi
}

select_stfu_binary() {
    case "$(uname -m)" in
        aarch64) echo "STFU.arm64" ;;
        armv7l|armv6l|armhf) echo "STFU.armhf" ;;
        x86_64|amd64) echo "STFU.amd64" ;;
        i386|i686) echo "STFU.i386" ;;
        *)
            echo "ERROR: Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

extract_existing_value() {
    local file="$1"
    local key="$2"

    if [[ -f "$file" ]]; then
        grep -E "^${key}=" "$file" | head -n1 | cut -d'"' -f2 || true
    fi
}

prompt_node_value() {
    local label="$1"
    local default_value="$2"
    local value=""

    while true; do
        if [[ -n "$default_value" ]]; then
            read -r -p "Enter ${label} [${default_value}]: " value
            value="${value:-$default_value}"
        else
            read -r -p "Enter ${label}: " value
        fi

        if [[ "$value" =~ ^[0-9]+$ ]]; then
            echo "$value"
            return
        fi

        echo "ERROR: ${label} must be digits only."
    done
}

need_root

if [[ ! -f "${REPO_DIR}/bm-stfu.sh" ]]; then
    echo "ERROR: bm-stfu.sh is missing from this package."
    exit 1
fi

if [[ ! -f "$DVSWITCH_INI" ]]; then
    echo "ERROR: DVSwitch.ini not found at $DVSWITCH_INI"
    echo "Make sure DVSwitch / MMDVM_Bridge is installed first."
    exit 1
fi

apt update
apt install -y git

if [[ ! -d "$STFU_REPO_DIR/.git" ]]; then
    git clone https://github.com/DVSwitch/STFU.git "$STFU_REPO_DIR"
else
    echo "STFU repo already exists at $STFU_REPO_DIR"
fi

BIN_NAME="$(select_stfu_binary)"
if [[ ! -f "$STFU_REPO_DIR/bin/$BIN_NAME" ]]; then
    echo "ERROR: Expected STFU binary not found: $STFU_REPO_DIR/bin/$BIN_NAME"
    exit 1
fi

EXISTING_MAIN="$(extract_existing_value "$BM_STFU_TARGET" "MAIN_NODE")"
EXISTING_DVSWITCH="$(extract_existing_value "$BM_STFU_TARGET" "DVSWITCH_NODE")"

if [[ "$EXISTING_MAIN" == "YOUR_NODE" ]]; then
    EXISTING_MAIN=""
fi
if [[ "$EXISTING_DVSWITCH" == "YOUR_DVSWITCH_NODE" ]]; then
    EXISTING_DVSWITCH=""
fi

echo
echo "Base STFU install requires your node values."
echo "These are NOT safe to hardcode in the repo."
echo "If you already have working values, you can press Enter to keep them."
echo

MAIN_NODE_VALUE="$(prompt_node_value "MAIN_NODE" "$EXISTING_MAIN")"
DVSWITCH_NODE_VALUE="$(prompt_node_value "DVSWITCH_NODE" "$EXISTING_DVSWITCH")"

install -m 0755 "$STFU_REPO_DIR/bin/$BIN_NAME" "$STFU_BIN_TARGET"
install -m 0755 "${REPO_DIR}/bm-stfu.sh" "$BM_STFU_TARGET"

sed -i "s/^MAIN_NODE=\"YOUR_NODE\"/MAIN_NODE=\"${MAIN_NODE_VALUE}\"/" "$BM_STFU_TARGET"
sed -i "s/^DVSWITCH_NODE=\"YOUR_DVSWITCH_NODE\"/DVSWITCH_NODE=\"${DVSWITCH_NODE_VALUE}\"/" "$BM_STFU_TARGET"

ln -sf "$DVSWITCH_INI" "$STFU_REPO_DIR/DVSwitch.ini"

echo
echo "Checking installed helper script syntax..."
bash -n "$BM_STFU_TARGET"

cat <<EOF

NEXT STEPS:

1) Edit your STFU settings in:
   /opt/MMDVM_Bridge/DVSwitch.ini

Make sure [STFU] has your real:
- BMPassword
- UserID
- TalkerAlias
- StartTG

2) Installed node values:
   MAIN_NODE="${MAIN_NODE_VALUE}"
   DVSWITCH_NODE="${DVSWITCH_NODE_VALUE}"

3) Use these commands:
   sudo bm-stfu.sh start 3220008
   sudo bm-stfu.sh tune 91
   sudo bm-stfu.sh stop
   sudo bm-stfu.sh status
EOF
