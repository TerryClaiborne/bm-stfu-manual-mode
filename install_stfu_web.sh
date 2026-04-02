#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBUI_DIR="${REPO_DIR}/web-ui"
TARGET_DIR="/var/www/html/stfu"
REQUIRED_BASE="/usr/local/bin/bm-stfu.sh"

LIVE_INDEX="${TARGET_DIR}/index.php"
LIVE_FAVORITES="${TARGET_DIR}/favorites.txt"
LIVE_README="${TARGET_DIR}/README.txt"
LIVE_SUDOERS_EXAMPLE="${TARGET_DIR}/sudoers-example.txt"

SUDOERS_TARGET="/etc/sudoers.d/stfu-web"
SUDOERS_LINE='www-data ALL=(ALL) NOPASSWD: /usr/local/bin/bm-stfu.sh'

echo "== STFU Web UI Installer =="

if [[ ! -f "${REQUIRED_BASE}" ]]; then
    echo
    echo "ERROR: Base bm-stfu-manual-mode is not installed."
    echo "Missing: ${REQUIRED_BASE}"
    echo "Install and configure the base project first, then run this installer again."
    exit 1
fi

if [[ ! -d "${WEBUI_DIR}" ]]; then
    echo
    echo "ERROR: Missing web-ui directory in repo:"
    echo "  ${WEBUI_DIR}"
    exit 1
fi

for file in index.php favorites.txt sudoers-example.txt README.md; do
    if [[ ! -f "${WEBUI_DIR}/${file}" ]]; then
        echo
        echo "ERROR: Missing required file:"
        echo "  ${WEBUI_DIR}/${file}"
        exit 1
    fi
done

echo
echo "Base install found:"
echo "  ${REQUIRED_BASE}"

echo
echo "Creating target directory if needed:"
echo "  ${TARGET_DIR}"
sudo mkdir -p "${TARGET_DIR}"

TIMESTAMP="$(date +%F-%H%M%S)"
BACKUP_DIR="${TARGET_DIR}/backup-${TIMESTAMP}"

if [[ -f "${LIVE_INDEX}" || -f "${LIVE_FAVORITES}" || -f "${LIVE_README}" || -f "${LIVE_SUDOERS_EXAMPLE}" ]]; then
    echo
    echo "Backing up existing live web UI files to:"
    echo "  ${BACKUP_DIR}"
    sudo mkdir -p "${BACKUP_DIR}"

    [[ -f "${LIVE_INDEX}" ]] && sudo cp "${LIVE_INDEX}" "${BACKUP_DIR}/index.php"
    [[ -f "${LIVE_FAVORITES}" ]] && sudo cp "${LIVE_FAVORITES}" "${BACKUP_DIR}/favorites.txt"
    [[ -f "${LIVE_README}" ]] && sudo cp "${LIVE_README}" "${BACKUP_DIR}/README.txt"
    [[ -f "${LIVE_SUDOERS_EXAMPLE}" ]] && sudo cp "${LIVE_SUDOERS_EXAMPLE}" "${BACKUP_DIR}/sudoers-example.txt"
fi

echo
echo "Installing web UI files..."
sudo cp "${WEBUI_DIR}/index.php" "${LIVE_INDEX}"
sudo cp "${WEBUI_DIR}/favorites.txt" "${LIVE_FAVORITES}"
sudo cp "${WEBUI_DIR}/README.md" "${LIVE_README}"
sudo cp "${WEBUI_DIR}/sudoers-example.txt" "${LIVE_SUDOERS_EXAMPLE}"

echo
echo "Setting ownership and permissions..."
sudo chown root:www-data "${LIVE_INDEX}"
sudo chmod 644 "${LIVE_INDEX}"

sudo chown www-data:www-data "${LIVE_FAVORITES}"
sudo chmod 664 "${LIVE_FAVORITES}"

sudo chown root:root "${LIVE_README}"
sudo chmod 644 "${LIVE_README}"

sudo chown root:root "${LIVE_SUDOERS_EXAMPLE}"
sudo chmod 644 "${LIVE_SUDOERS_EXAMPLE}"

echo
echo "Checking PHP syntax..."
sudo php -l "${LIVE_INDEX}"

echo
echo "Installing sudoers rule..."
SUDOERS_TMP="$(mktemp)"
printf '%s\n' "${SUDOERS_LINE}" > "${SUDOERS_TMP}"

SUDOERS_BACKUP=""
if [[ -f "${SUDOERS_TARGET}" ]]; then
    SUDOERS_BACKUP="${SUDOERS_TARGET}.bak.${TIMESTAMP}"
    echo "Existing sudoers file found. Backing it up to:"
    echo "  ${SUDOERS_BACKUP}"
    sudo cp "${SUDOERS_TARGET}" "${SUDOERS_BACKUP}"
fi

sudo cp "${SUDOERS_TMP}" "${SUDOERS_TARGET}"
rm -f "${SUDOERS_TMP}"

sudo chown root:root "${SUDOERS_TARGET}"
sudo chmod 440 "${SUDOERS_TARGET}"

if ! sudo visudo -cf "${SUDOERS_TARGET}"; then
    echo
    echo "ERROR: sudoers validation failed."
    if [[ -n "${SUDOERS_BACKUP}" && -f "${SUDOERS_BACKUP}" ]]; then
        echo "Restoring previous sudoers file..."
        sudo cp "${SUDOERS_BACKUP}" "${SUDOERS_TARGET}"
        sudo chown root:root "${SUDOERS_TARGET}"
        sudo chmod 440 "${SUDOERS_TARGET}"
        sudo visudo -cf "${SUDOERS_TARGET}" || true
    else
        echo "Removing invalid sudoers file..."
        sudo rm -f "${SUDOERS_TARGET}"
    fi
    exit 1
fi

echo
echo "Testing bm-stfu.sh as www-data..."
sudo -u www-data sudo /usr/local/bin/bm-stfu.sh status >/dev/null

echo
echo "Install complete."
echo
echo "Live files:"
echo "  ${LIVE_INDEX}"
echo "  ${LIVE_FAVORITES}"
echo "  ${LIVE_README}"
echo "  ${LIVE_SUDOERS_EXAMPLE}"
echo
echo "Installed sudoers file:"
echo "  ${SUDOERS_TARGET}"
echo
echo "Web UI URL:"
echo "  http://$(hostname -I | awk '{print $1}')/stfu/"
