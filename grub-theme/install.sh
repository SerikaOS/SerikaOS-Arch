#!/bin/bash
# ============================================================
# SerikaOS — GRUB Theme Installer
# Installs the SerikaOS GRUB theme and configures GRUB
# ============================================================

set -euo pipefail

PINK='\033[38;2;232;160;191m'
TEAL='\033[38;2;92;198;208m'
DIM='\033[38;2;106;106;138m'
GOLD='\033[38;2;212;168;83m'
RESET='\033[0m'
BOLD='\033[1m'

THEME_NAME="SerikaOS"
THEME_DIR="/boot/grub/themes/${THEME_NAME}"
GRUB_DEFAULT="/etc/default/grub"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${PINK}${BOLD}  SerikaOS GRUB Theme Installer${RESET}"
echo -e "${DIM}  ─────────────────────────────${RESET}"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${GOLD}[!]${RESET} Must be run as root: sudo bash install.sh"
    exit 1
fi

# Install theme files
echo -e "${TEAL}[*]${RESET} Installing theme to ${THEME_DIR}..."
mkdir -p "${THEME_DIR}"
cp -r "${SCRIPT_DIR}/"* "${THEME_DIR}/"
rm -f "${THEME_DIR}/install.sh"  # Don't copy the installer script itself

# Generate PF2 fonts if tools available
if command -v grub-mkfont &>/dev/null; then
    echo -e "${TEAL}[*]${RESET} Generating GRUB fonts..."
    mkdir -p "${THEME_DIR}/fonts"
    FONT_SRC=""
    for f in /usr/share/fonts/TTF/DejaVuSans.ttf \
             /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
             /usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf; do
        [[ -f "$f" ]] && FONT_SRC="$f" && break
    done
    FONT_BOLD=""
    for f in /usr/share/fonts/TTF/DejaVuSans-Bold.ttf \
             /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf \
             /usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf; do
        [[ -f "$f" ]] && FONT_BOLD="$f" && break
    done

    if [[ -n "$FONT_SRC" ]]; then
        grub-mkfont -s 11 -o "${THEME_DIR}/fonts/dejavu_11.pf2" "$FONT_SRC"
        grub-mkfont -s 12 -o "${THEME_DIR}/fonts/dejavu_12.pf2" "$FONT_SRC"
        grub-mkfont -s 14 -o "${THEME_DIR}/fonts/dejavu_14.pf2" "$FONT_SRC"
        grub-mkfont -s 16 -o "${THEME_DIR}/fonts/dejavu_16.pf2" "$FONT_SRC"
        grub-mkfont -s 24 -o "${THEME_DIR}/fonts/dejavu_24.pf2" "$FONT_SRC"
        echo -e "${PINK}[✓]${RESET} Regular fonts generated."
    fi
    if [[ -n "$FONT_BOLD" ]]; then
        grub-mkfont -s 16 -o "${THEME_DIR}/fonts/dejavu_bold_16.pf2" "$FONT_BOLD"
        grub-mkfont -s 24 -o "${THEME_DIR}/fonts/dejavu_bold_24.pf2" "$FONT_BOLD"
        echo -e "${PINK}[✓]${RESET} Bold fonts generated."
    fi
fi

# Configure GRUB
echo -e "${TEAL}[*]${RESET} Configuring GRUB..."

if [[ -f "$GRUB_DEFAULT" ]]; then
    # Backup original
    cp "${GRUB_DEFAULT}" "${GRUB_DEFAULT}.bak.$(date +%s)"

    # Set theme
    if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT"; then
        sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" "$GRUB_DEFAULT"
    elif grep -q "^#GRUB_THEME=" "$GRUB_DEFAULT"; then
        sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" "$GRUB_DEFAULT"
    else
        echo "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" >> "$GRUB_DEFAULT"
    fi

    # Set graphics mode
    if grep -q "^GRUB_GFXMODE=" "$GRUB_DEFAULT"; then
        sed -i 's|^GRUB_GFXMODE=.*|GRUB_GFXMODE="auto"|' "$GRUB_DEFAULT"
    elif grep -q "^#GRUB_GFXMODE=" "$GRUB_DEFAULT"; then
        sed -i 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE="auto"|' "$GRUB_DEFAULT"
    else
        echo 'GRUB_GFXMODE="auto"' >> "$GRUB_DEFAULT"
    fi

    # Regenerate grub config
    echo -e "${TEAL}[*]${RESET} Regenerating grub.cfg..."
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null

    echo ""
    echo -e "${PINK}[✓]${RESET} SerikaOS GRUB theme installed successfully!"
else
    echo -e "${GOLD}[!]${RESET} ${GRUB_DEFAULT} not found. Please configure GRUB manually."
    echo -e "${DIM}    Set GRUB_THEME=\"${THEME_DIR}/theme.txt\"${RESET}"
fi

echo ""
