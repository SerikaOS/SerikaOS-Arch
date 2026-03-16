#!/bin/bash
# ============================================================
# SerikaOS — Demo ISO Builder
# Creates a minimal bootable demo showcasing the GRUB theme,
# branding, and live shell. Does NOT require Arch Linux.
# Useful for testing themes without a full ISO build.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="${SCRIPT_DIR}/iso-build"
INITRD_DIR="${SCRIPT_DIR}/initrd-build"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_NAME="serikaos-demo-$(date +%Y%m%d).iso"

PINK='\033[38;2;232;160;191m'
TEAL='\033[38;2;92;198;208m'
GOLD='\033[38;2;212;168;83m'
DIM='\033[38;2;106;106;138m'
RED='\033[38;2;255;107;107m'
RESET='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${PINK}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║${RESET}  ${TEAL}${BOLD}SerikaOS${RESET} ${DIM}— Demo ISO Builder${RESET}                           ${PINK}║${RESET}"
echo -e "${PINK}║${RESET}  ${DIM}Minimal bootable demo for testing themes & branding${RESET}    ${PINK}║${RESET}"
echo -e "${PINK}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Pre-flight
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗]${RESET} Must be run as root."
    exit 1
fi

for cmd in grub-mkrescue xorriso; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[✗]${RESET} Missing: $cmd"
        echo -e "${DIM}    Install: sudo apt install grub-common xorriso${RESET}"
        exit 1
    fi
done

echo -e "${TEAL}[*]${RESET} Cleaning previous builds..."
rm -rf "${ISO_DIR}" "${INITRD_DIR}"
mkdir -p "${ISO_DIR}"/{boot/grub/themes/SerikaOS,boot/grub/fonts}
mkdir -p "${OUT_DIR}"

# ═════════════════════════════════════════════════════
# 1. BUILD INITRAMFS
# ═════════════════════════════════════════════════════
echo -e "${TEAL}[*]${RESET} Building initramfs..."
mkdir -p "${INITRD_DIR}"/{bin,sbin,etc,proc,sys,dev,tmp,run,root,usr/bin,usr/sbin}

# Copy busybox
BUSYBOX=$(which busybox 2>/dev/null || echo "/bin/busybox")
if [[ ! -x "$BUSYBOX" ]]; then
    echo -e "${RED}[✗]${RESET} busybox not found. Install: sudo apt install busybox-static"
    exit 1
fi
cp "$BUSYBOX" "${INITRD_DIR}/bin/busybox"
chmod +x "${INITRD_DIR}/bin/busybox"

# Create applet symlinks
chroot "${INITRD_DIR}" /bin/busybox --install -s /bin 2>/dev/null || \
    (cd "${INITRD_DIR}/bin" && for a in sh ash ls cat echo mount umount mkdir rm cp mv ln chmod grep sed awk sort head tail wc clear reset date hostname uname dmesg sleep vi ping tee tr cut free ps kill df du env test true false poweroff reboot; do ln -sf busybox "$a" 2>/dev/null || true; done)

ln -sf /bin/busybox "${INITRD_DIR}/sbin/init"

# Create init script
cat > "${INITRD_DIR}/init" << 'INITSCRIPT'
#!/bin/sh
# SerikaOS Demo — Init (PID 1)

/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox mount -t devtmpfs devtmpfs /dev 2>/dev/null
/bin/busybox mkdir -p /dev/pts /dev/shm
/bin/busybox mount -t devpts devpts /dev/pts 2>/dev/null
/bin/busybox mount -t tmpfs tmpfs /tmp
/bin/busybox mount -t tmpfs tmpfs /run

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export TERM=linux
export SHELL=/bin/sh

/bin/busybox hostname serikaos
/bin/busybox clear

# ── SerikaOS Welcome ──
P="\033[38;2;232;160;191m"
T="\033[38;2;92;198;208m"
G="\033[38;2;212;168;83m"
D="\033[38;2;106;106;138m"
R="\033[0m"
B="\033[1m"

echo ""
echo -e "${P}   ███████╗███████╗██████╗ ██╗██╗  ██╗ █████╗ ${T} ██████╗ ███████╗${R}"
echo -e "${P}   ██╔════╝██╔════╝██╔══██╗██║██║ ██╔╝██╔══██╗${T}██╔═══██╗██╔════╝${R}"
echo -e "${P}   ███████╗█████╗  ██████╔╝██║█████╔╝ ███████║${T}██║   ██║███████╗${R}"
echo -e "${P}   ╚════██║██╔══╝  ██╔══██╗██║██╔═██╗ ██╔══██║${T}██║   ██║╚════██║${R}"
echo -e "${P}   ███████║███████╗██║  ██║██║██║  ██╗██║  ██║${T}╚██████╔╝███████║${R}"
echo -e "${P}   ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝${T} ╚═════╝ ╚══════╝${R}"
echo ""
echo -e "${D}   Your system. Your rules. Zero bloatware.${R}"
echo ""
echo -e "${P}   ═══════════════════════════════════════════════════${R}"
echo ""
echo -e "   ${T}✓${R} GRUB Theme loaded"
echo -e "   ${T}✓${R} Live environment booted"
echo -e "   ${G}⚡${R} Demo Mode — minimal shell"
echo ""
echo -e "   ${D}In the full release, this boots into KDE Plasma${R}"
echo -e "   ${D}with the Calamares GUI installer.${R}"
echo ""
echo -e "   ${P}Commands:${R} neofetch  about  colors  help  poweroff"
echo ""

# Helper commands
cat > /bin/neofetch << 'NF'
#!/bin/sh
P="\033[38;2;232;160;191m"
T="\033[38;2;92;198;208m"
D="\033[38;2;106;106;138m"
R="\033[0m"
B="\033[1m"
MEM_TOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{printf "%.0f", $2/1024}')
MEM_USED=$(cat /proc/meminfo | grep -E "MemTotal|MemAvailable" | awk 'NR==1{t=$2}NR==2{printf "%.0f", (t-$2)/1024}')
UP=$(cat /proc/uptime | cut -d. -f1)

echo ""
echo -e "${P}${B}   ███████╗${R}        ${T}${B}serika${D}@${T}os${R}"
echo -e "${P}${B}   ██╔════╝${R}        ${D}──────────────────${R}"
echo -e "${P}${B}   ███████╗${R}        ${T}OS:${R}      SerikaOS"
echo -e "${P}${B}   ╚════██║${R}        ${T}Kernel:${R}  $(uname -r)"
echo -e "${P}${B}   ███████║${R}        ${T}Shell:${R}   sh (busybox)"
echo -e "${P}${B}   ╚══════╝${R}        ${T}Theme:${R}   Serika Kuromi"
echo -e "                    ${T}Uptime:${R}  ${UP}s"
echo -e "   ${P}██████╗ ███████╗${R}  ${T}Memory:${R}  ${MEM_USED}/${MEM_TOTAL} MB"
echo -e "   ${P}██╔═══██╗██╔════╝${R}"
echo -e "   ${P}██║   ██║███████╗${R}  ${D}Serika Kuromi — Blue Archive${R}"
echo -e "   ${P}╚██████╔╝╚══════╝${R}"
echo ""
echo -e "   \033[48;2;26;27;46m  \033[48;2;42;43;62m  \033[48;2;232;160;191m  \033[48;2;92;198;208m  \033[48;2;212;168;83m  \033[48;2;200;200;216m  \033[48;2;106;106;138m  \033[0m"
echo ""
NF
chmod +x /bin/neofetch

cat > /bin/about << 'AB'
#!/bin/sh
P="\033[38;2;232;160;191m"; T="\033[38;2;92;198;208m"; D="\033[38;2;106;106;138m"; R="\033[0m"; B="\033[1m"
echo ""
echo -e "  ${P}${B}SerikaOS${R} — A premium rolling Linux distribution"
echo -e "  ${D}Themed around Serika Kuromi from Blue Archive${R}"
echo ""
echo -e "  ${T}Philosophy:${R}"
echo "    ✦ Your system, your rules — every decision is yours"
echo "    ✦ Zero bloatware — everything is opt-in"
echo "    ✦ Privacy first — DNS-over-HTTPS, MAC randomization"
echo "    ✦ Rolling-release power — fast updates, full user control"
echo "    ✦ Beautiful by default — every pixel themed with care"
echo ""
echo -e "  ${T}Features:${R}"
echo "    ✦ 9 Desktop Environments • 4 Kernels • 3 Bootloaders"
echo "    ✦ Full privacy hardening suite • Custom theming"
echo "    ✦ Premium GRUB + SDDM + Calamares installer themes"
echo ""
AB
chmod +x /bin/about

cat > /bin/colors << 'CL'
#!/bin/sh
echo ""
echo -e "\033[38;2;232;160;191m  SerikaOS Color Palette\033[0m"
echo ""
echo -e "  \033[48;2;18;19;31m      \033[0m  #12131f  Deep Navy"
echo -e "  \033[48;2;26;27;46m      \033[0m  #1a1b2e  Dark Navy"
echo -e "  \033[48;2;42;43;62m      \033[0m  #2a2b3e  Mid Navy"
echo -e "  \033[48;2;58;59;78m      \033[0m  #3a3b4e  Soft Navy"
echo -e "  \033[48;2;232;160;191m      \033[0m  #e8a0bf  Soft Pink"
echo -e "  \033[48;2;92;198;208m      \033[0m  #5cc6d0  Teal"
echo -e "  \033[48;2;212;168;83m      \033[0m  #d4a853  Warm Gold"
echo -e "  \033[48;2;200;200;216m      \033[0m  #c8c8d8  Light Gray"
echo -e "  \033[48;2;106;106;138m      \033[0m  #6a6a8a  Dim Gray"
echo ""
CL
chmod +x /bin/colors

cat > /bin/help << 'HL'
#!/bin/sh
P="\033[38;2;232;160;191m"; T="\033[38;2;92;198;208m"; D="\033[38;2;106;106;138m"; R="\033[0m"
echo ""
echo -e "${T}SerikaOS Demo Commands:${R}"
echo -e "  ${P}neofetch${R}   — System info with SerikaOS branding"
echo -e "  ${P}about${R}      — About SerikaOS"
echo -e "  ${P}colors${R}     — SerikaOS color palette"
echo -e "  ${P}poweroff${R}   — Shut down"
echo -e "  ${P}reboot${R}     — Reboot"
echo ""
HL
chmod +x /bin/help

cat > /bin/poweroff << 'PO'
#!/bin/sh
echo -e "\033[38;2;232;160;191mShutting down SerikaOS...\033[0m"
sleep 1
/bin/busybox poweroff -f
PO
chmod +x /bin/poweroff

cat > /bin/reboot << 'RB'
#!/bin/sh
echo -e "\033[38;2;92;198;208mRebooting SerikaOS...\033[0m"
sleep 1
/bin/busybox reboot -f
RB
chmod +x /bin/reboot

# Shell profile
cat > /root/.profile << 'PROF'
export PS1='\[\033[38;2;232;160;191m\]serika\[\033[38;2;106;106;138m\]@\[\033[38;2;92;198;208m\]os \[\033[38;2;212;168;83m\]➜ \[\033[0m\]'
export HOME=/root
export TERM=linux
export SHELL=/bin/sh
PROF

/bin/busybox mkdir -p /etc
echo "root::0:0:root:/root:/bin/sh" > /etc/passwd
echo "root:x:0:" > /etc/group

exec /bin/busybox setsid /bin/busybox sh -l < /dev/console > /dev/console 2>&1
INITSCRIPT
chmod +x "${INITRD_DIR}/init"

# Pack initramfs
echo -e "${TEAL}[*]${RESET} Packing initramfs..."
cd "${INITRD_DIR}"
find . -print0 | cpio --null -o --format=newc 2>/dev/null | gzip -9 > "${ISO_DIR}/boot/initrd.img"
cd "${SCRIPT_DIR}"
echo -e "${PINK}[✓]${RESET} Initramfs: $(du -h "${ISO_DIR}/boot/initrd.img" | cut -f1)"

# ═════════════════════════════════════════════════════
# 2. COPY KERNEL
# ═════════════════════════════════════════════════════
echo -e "${TEAL}[*]${RESET} Copying kernel..."
KERN=$(ls /boot/vmlinuz-* 2>/dev/null | head -1)
if [[ -z "$KERN" ]]; then
    echo -e "${RED}[✗]${RESET} No kernel found in /boot/"
    exit 1
fi
cp "$KERN" "${ISO_DIR}/boot/vmlinuz"
echo -e "${PINK}[✓]${RESET} Kernel: $(basename $KERN)"

# ═════════════════════════════════════════════════════
# 3. GRUB THEME
# ═════════════════════════════════════════════════════
echo -e "${TEAL}[*]${RESET} Copying GRUB theme..."
cp -r "${SCRIPT_DIR}/grub-theme/"* "${ISO_DIR}/boot/grub/themes/SerikaOS/" 2>/dev/null || true
rm -f "${ISO_DIR}/boot/grub/themes/SerikaOS/install.sh"

# Generate fonts
FONT_SRC=""
for f in /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /usr/share/fonts/TTF/DejaVuSans.ttf; do
    [[ -f "$f" ]] && FONT_SRC="$f" && break
done
if [[ -n "$FONT_SRC" ]] && command -v grub-mkfont &>/dev/null; then
    for size in 11 12 14 16 24; do
        grub-mkfont -s $size -o "${ISO_DIR}/boot/grub/fonts/dejavu${size}.pf2" "$FONT_SRC"
    done
fi

# ═════════════════════════════════════════════════════
# 4. GRUB CONFIG
# ═════════════════════════════════════════════════════
echo -e "${TEAL}[*]${RESET} Creating GRUB config..."
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'GRUBCFG'
insmod all_video
insmod gfxterm
insmod gfxmenu
insmod png
insmod jpeg

set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

set theme=/boot/grub/themes/SerikaOS/theme.txt
export theme

set default=0
set timeout=10

menuentry '  Try SerikaOS — Live Session' --class serikaos --class linux {
    linux /boot/vmlinuz rdinit=/init console=ttyS0 console=tty0
    initrd /boot/initrd.img
}

menuentry '  Install SerikaOS' --class serikaos --class linux {
    linux /boot/vmlinuz rdinit=/init console=ttyS0 console=tty0 serikaos.install=1
    initrd /boot/initrd.img
}

submenu '  Advanced Options >' --class submenu {
    menuentry '  SerikaOS (Safe Graphics)' --class serikaos {
        linux /boot/vmlinuz rdinit=/init nomodeset console=tty0
        initrd /boot/initrd.img
    }
    menuentry '  Boot from local disk' --class hd {
        exit
    }
}

menuentry '  Reboot' --class restart { reboot }
menuentry '  Shut Down' --class shutdown { halt }
GRUBCFG

# ═════════════════════════════════════════════════════
# 5. BUILD ISO
# ═════════════════════════════════════════════════════
echo -e "${TEAL}[*]${RESET} Building demo ISO..."
grub-mkrescue -o "${OUT_DIR}/${ISO_NAME}" "${ISO_DIR}" -- -volid "SERIKAOS" 2>&1 | tail -5

echo ""
if [[ -f "${OUT_DIR}/${ISO_NAME}" ]]; then
    echo -e "${PINK}[✓]${RESET} Demo ISO built: ${OUT_DIR}/${ISO_NAME}"
    echo -e "${TEAL}    Size:${RESET} $(du -h "${OUT_DIR}/${ISO_NAME}" | cut -f1)"
else
    echo -e "${RED}[✗]${RESET} Build failed."
    exit 1
fi

# Cleanup
rm -rf "${ISO_DIR}" "${INITRD_DIR}"

echo ""
echo -e "${DIM}Test: qemu-system-x86_64 -cdrom ${OUT_DIR}/${ISO_NAME} -m 2G -enable-kvm${RESET}"
echo ""
