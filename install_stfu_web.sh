#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBUI_DIR="${REPO_DIR}/web-ui"
TARGET_DIR="/var/www/html/stfu"
REQUIRED_BASE="/usr/local/bin/bm-stfu.sh"

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

if [[ -f "${TARGET_DIR}/index.php" || -f "${TARGET_DIR}/favorites.txt" || -f "${TARGET_DIR}/README.txt" || -f "${TARGET_DIR}/sudoers-example.txt" ]]; then
    echo
    echo "Backing up existing live web UI files to:"
    echo "  ${BACKUP_DIR}"
    sudo mkdir -p "${BACKUP_DIR}"

    [[ -f "${TARGET_DIR}/index.php" ]] && sudo cp "${TARGET_DIR}/index.php" "${BACKUP_DIR}/index.php"
    [[ -f "${TARGET_DIR}/favorites.txt" ]] && sudo cp "${TARGET_DIR}/favorites.txt" "${BACKUP_DIR}/favorites.txt"
    [[ -f "${TARGET_DIR}/README.txt" ]] && sudo cp "${TARGET_DIR}/README.txt" "${BACKUP_DIR}/README.txt"
    [[ -f "${TARGET_DIR}/sudoers-example.txt" ]] && sudo cp "${TARGET_DIR}/sudoers-example.txt" "${BACKUP_DIR}/sudoers-example.txt"
fi

echo
echo "Installing web UI files..."
sudo cp "${WEBUI_DIR}/index.php" "${TARGET_DIR}/index.php"
sudo cp "${WEBUI_DIR}/favorites.txt" "${TARGET_DIR}/favorites.txt"
sudo cp "${WEBUI_DIR}/README.md" "${TARGET_DIR}/README.txt"
sudo cp "${WEBUI_DIR}/sudoers-example.txt" "${TARGET_DIR}/sudoers-example.txt"

echo
echo "Setting ownership and permissions..."
sudo chown root:www-data "${TARGET_DIR}/index.php"
sudo chmod 644 "${TARGET_DIR}/index.php"

sudo chown www-data:www-data "${TARGET_DIR}/favorites.txt"
sudo chmod 664 "${TARGET_DIR}/favorites.txt"

sudo chown root:root "${TARGET_DIR}/README.txt"
sudo chmod 644 "${TARGET_DIR}/README.txt"

sudo chown root:root "${TARGET_DIR}/sudoers-example.txt"
sudo chmod 644 "${TARGET_DIR}/sudoers-example.txt"

echo
echo "Checking PHP syntax..."
sudo php -l "${TARGET_DIR}/index.php"

echo
echo "Install complete."
echo
echo "Live files:"
echo "  ${TARGET_DIR}/index.php"
echo "  ${TARGET_DIR}/favorites.txt"
echo "  ${TARGET_DIR}/README.txt"
echo "  ${TARGET_DIR}/sudoers-example.txt"
echo
echo "IMPORTANT:"
echo "This installer does not auto-install the sudoers file."
echo "Review:"
echo "  ${TARGET_DIR}/sudoers-example.txt"
echo
echo "Then install/validate your sudoers rule as needed, for example:"
echo "  sudo cp ${TARGET_DIR}/sudoers-example.txt /etc/sudoers.d/stfu-web"
echo "  sudo visudo -cf /etc/sudoers.d/stfu-web"
echo
echo "Web UI URL:"
echo "  http://$(hostname -I | awk '{print $1}')/stfu/"