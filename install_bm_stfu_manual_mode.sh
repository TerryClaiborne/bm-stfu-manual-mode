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

install -m 0755 "$STFU_REPO_DIR/bin/$BIN_NAME" "$STFU_BIN_TARGET"
install -m 0755 "${REPO_DIR}/bm-stfu.sh" "$BM_STFU_TARGET"

ln -sf "$DVSWITCH_INI" "$STFU_REPO_DIR/DVSwitch.ini"

cat <<EOF

Install complete.

Installed:
  $STFU_BIN_TARGET
  $BM_STFU_TARGET

Created / updated:
  $STFU_REPO_DIR/DVSwitch.ini -> $DVSWITCH_INI

NEXT STEPS:

1) Edit your STFU settings in:
   /opt/MMDVM_Bridge/DVSwitch.ini

   Make sure [STFU] has your real:
   - BMPassword
   - UserID
   - TalkerAlias
   - StartTG

2) Edit your node numbers in:
   /usr/local/bin/bm-stfu.sh

   Change:
   MAIN_NODE="67040"
   DVSWITCH_NODE="1957"

   to match your system.

3) Use these commands:
   sudo bm-stfu.sh start 3220008
   sudo bm-stfu.sh tune 91
   sudo bm-stfu.sh stop
   sudo bm-stfu.sh status

EOF
