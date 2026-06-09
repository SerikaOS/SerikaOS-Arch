#!/bin/bash
# ============================================================
# SerikaOS — ISO Builder (Docker Wrapper)
# Builds the ISO inside an Arch Linux container for
# reproducibility and cross-distro compatibility.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"
CACHE_DIR="${SCRIPT_DIR}/build-cache"
YAY_CACHE="${CACHE_DIR}/yay"
PACMAN_CACHE="${CACHE_DIR}/pacman"

# Colors
PINK='\033[38;2;232;160;191m'
TEAL='\033[38;2;92;198;208m'
GOLD='\033[38;2;212;168;83m'
DIM='\033[38;2;106;106;138m'
RED='\033[38;2;255;107;107m'
RESET='\033[0m'
BOLD='\033[1m'

export ISO_VERSION=$(date +%Y.%m.%d)
export ISO_LABEL="SERIKAOS_$(date +%Y%m)"
ISO_FILENAME="serikaos-${ISO_VERSION}-x86_64.iso"

echo ""
echo -e "${PINK}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║${RESET}  ${TEAL}${BOLD}SerikaOS${RESET} ${DIM}— ISO Builder (Containerized)${RESET}               ${PINK}║${RESET}"
echo -e "${PINK}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Pre-flight
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗]${RESET} Must be run as root: sudo bash build-docker-iso.sh"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo -e "${RED}[✗]${RESET} Docker is not installed. Install it first:"
    echo -e "    ${DIM}sudo pacman -S docker && sudo systemctl start docker${RESET}"
    exit 1
fi

mkdir -p "${OUT_DIR}" "${WORK_DIR}" "${YAY_CACHE}" "${PACMAN_CACHE}" "${CACHE_DIR}/repo" "${CACHE_DIR}/tmp"

# Always start fresh (work dir + profile cache must be clean for mkarchiso)
# AUR packages and pacman cache are preserved to speed up rebuilds
echo -e "${TEAL}[*]${RESET} Cleaning previous build artifacts..."
rm -rf "${WORK_DIR:?}"/*
rm -rf "${CACHE_DIR}/tmp"/*
rm -f "${OUT_DIR}"/serikaos-*.iso

# Pull latest Arch image
echo -e "${TEAL}[*]${RESET} Pulling archlinux:latest..."
docker pull archlinux:latest 2>&1 | tail -3

# Run containerized build
echo -e "${TEAL}[*]${RESET} Starting build inside Arch Linux container..."
echo -e "${DIM}    Memory Limit: 12GB | Swap Limit: 14GB${RESET}"
echo -e "${DIM}    This handles all dependencies automatically.${RESET}"
echo ""

docker run --rm --privileged \
    --memory="12g" \
    --memory-swap="14g" \
    -v "${SCRIPT_DIR}:/serikaos:ro" \
    -v "${OUT_DIR}:/out" \
    -v "${WORK_DIR}:/work" \
    -v "${YAY_CACHE}:/home/builduser/.cache/yay" \
    -v "${PACMAN_CACHE}:/var/cache/pacman/pkg" \
    -v "${CACHE_DIR}/repo:/serikaos-repo" \
    -v "${CACHE_DIR}/tmp:/tmp/serikaos-profile" \
    -e ISO_VERSION="${ISO_VERSION}" \
    -e ISO_LABEL="${ISO_LABEL}" \
    -e SERIKA_WORK_DIR="/work" \
    -e SERIKA_OUT_DIR="/out" \
    -e SERIKA_PROFILE_DIR="/tmp/serikaos-profile" \
    --network host \
    archlinux:latest \
    /bin/bash /serikaos/inner-build.sh

echo ""

# Check result
RECENT_ISO=$(ls -1t "${OUT_DIR}"/serikaos-*.iso 2>/dev/null | head -n 1)
if [[ -n "$RECENT_ISO" ]]; then
    echo -e "${PINK}[✓]${RESET} Built: $(basename "$RECENT_ISO")"
    echo -e "${TEAL}    Path:${RESET} ${RECENT_ISO}"
    echo -e "${TEAL}    Size:${RESET} $(du -h "$RECENT_ISO" | cut -f1)"
else
    echo -e "${RED}[✗]${RESET} ISO build failed — no output file found."
    exit 1
fi

echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo -e "  ${DIM}Test in QEMU:      qemu-system-x86_64 -cdrom ${RECENT_ISO} -m 4G -enable-kvm${RESET}"
echo -e "  ${DIM}Test in VBox:      Create VM (Arch 64), attach ISO${RESET}"
echo -e "  ${DIM}Write to USB:      sudo dd bs=4M if=${RECENT_ISO} of=/dev/sdX status=progress${RESET}"
echo ""
