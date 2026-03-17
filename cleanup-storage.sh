#!/bin/bash
# ============================================================
# SerikaOS — Storage Cleanup Script
# Run this with sudo to reclaim space from failed builds.
# ============================================================

set -u

# Colors
PINK='\033[38;2;232;160;191m'
TEAL='\033[38;2;92;198;208m'
RED='\033[38;2;255;107;107m'
RESET='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗]${RESET} This script must be run as root: sudo bash cleanup-storage.sh"
    exit 1
fi

echo -e "${TEAL}[*]${RESET} Cleaning up Docker artifacts..."
docker system prune -af --volumes 2>/dev/null || echo "Docker prune failed (maybe docker not running?)"

echo -e "${TEAL}[*]${RESET} Cleaning up archiso temporary directories..."
rm -rf /tmp/archiso-work /tmp/serikaos-profile
rm -rf /home/builduser/.cache/yay

echo -e "${TEAL}[*]${RESET} Cleaning up pacman cache (Host & Container targets)..."
if command -v pacman &>/dev/null; then
    pacman -Scc --noconfirm
fi

echo -e "${TEAL}[*]${RESET} Cleaning up local project artifacts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "${SCRIPT_DIR}/work"
rm -rf "${SCRIPT_DIR}/out"
rm -rf "${SCRIPT_DIR}/build-cache"

echo -e "${PINK}[✓]${RESET} Storage cleanup complete!"
df -h /
