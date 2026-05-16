#!/bin/bash
# Miku SDDM — Installer
# Part of the Miku desktop theming project.
set -e

THEME_NAME="miku"
THEME_DIR="/usr/share/sddm/themes/${THEME_NAME}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} Miku SDDM — Installer"

# ── Root check ───────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Please run as root (use sudo)."
    exit 1
fi

# ── Require Qt6 greeter ──────────────────────────────────────────────────
if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    echo -e "${RED}Error:${NC} sddm-greeter-qt6 not found. Miku requires Qt6."
    exit 1
fi

# ── Install ──────────────────────────────────────────────────────────────
if [ -d "${THEME_DIR}" ]; then
    echo -e "${BLUE}==>${NC} Removing previous install..."
    rm -rf "${THEME_DIR}"
fi

echo -e "${BLUE}==>${NC} Installing to ${THEME_DIR}..."
mkdir -p "${THEME_DIR}/components" "${THEME_DIR}/assets"
cp "${SCRIPT_DIR}/Main.qml"         "${THEME_DIR}/"
cp "${SCRIPT_DIR}/theme.conf"       "${THEME_DIR}/"
cp "${SCRIPT_DIR}/metadata.desktop" "${THEME_DIR}/"
cp "${SCRIPT_DIR}/components/"*     "${THEME_DIR}/components/"
cp "${SCRIPT_DIR}/assets/"*         "${THEME_DIR}/assets/"
chmod -R 755 "${THEME_DIR}"

echo -e "${GREEN}Done.${NC}"

# ── Apply as active theme? ───────────────────────────────────────────────
echo ""
read -p "Apply Miku as your active SDDM theme now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p /etc/sddm.conf.d
    printf "[Theme]\nCurrent=${THEME_NAME}\n" > /etc/sddm.conf.d/theme.conf
    echo -e "${GREEN}Theme applied.${NC} Will take effect on next login."
else
    echo -e "To apply manually, set ${GREEN}Current=${THEME_NAME}${NC} in /etc/sddm.conf.d/theme.conf"
fi

echo ""
echo -e "Test with: ${BLUE}sddm-greeter-qt6 --test-mode --theme ${THEME_DIR}${NC}"
