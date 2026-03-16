#!/bin/bash
# ============================================================
# SerikaOS — ISO Build Script
# Builds a bootable SerikaOS installation ISO using archiso
# ============================================================

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${SCRIPT_DIR}/archiso-profile"
WORK_DIR="${SCRIPT_DIR}/work"
OUT_DIR="${SCRIPT_DIR}/out"

# Colors
PINK='\033[38;2;232;160;191m'
TEAL='\033[38;2;92;198;208m'
GOLD='\033[38;2;212;168;83m'
DIM='\033[38;2;106;106;138m'
RED='\033[38;2;255;107;107m'
RESET='\033[0m'
BOLD='\033[1m'

banner() {
    echo ""
    echo -e "${PINK}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}  ${TEAL}${BOLD}SerikaOS${RESET} ${DIM}— Premium Rolling • Privacy-Focused${RESET}         ${PINK}║${RESET}"
    echo -e "${PINK}║${RESET}  ${DIM}Themed around Serika Kuromi — Blue Archive${RESET}             ${PINK}║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

log()     { echo -e "${TEAL}[*]${RESET} $1"; }
success() { echo -e "${PINK}[✓]${RESET} $1"; }
warn()    { echo -e "${GOLD}[!]${RESET} $1"; }
error()   { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

# --- Pre-flight Checks ---
preflight() {
    log "Running pre-flight checks..."

    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root: sudo bash build.sh"
    fi

    if ! command -v mkarchiso &>/dev/null; then
        error "archiso is not installed. Run: pacman -S archiso"
    fi

    # Check that profile directory exists and is valid
    if [[ ! -f "${PROFILE_DIR}/profiledef.sh" ]]; then
        error "Profile not found at ${PROFILE_DIR}/profiledef.sh"
    fi

    if [[ ! -f "${PROFILE_DIR}/packages.x86_64" ]]; then
        error "Package list not found at ${PROFILE_DIR}/packages.x86_64"
    fi

    # Disk space check
    local available_gb
    available_gb=$(df --output=avail -BG "${SCRIPT_DIR}" | tail -1 | tr -d ' G')
    if [[ "$available_gb" -lt 8 ]]; then
        warn "Low disk space: ${available_gb}GB available (8GB+ recommended)"
    fi

    success "Pre-flight checks passed."
}

# --- Prepare Profile ---
prepare_profile() {
    log "Preparing archiso profile..."

    local iso_label
    iso_label=$(source "${PROFILE_DIR}/profiledef.sh" 2>/dev/null && echo "${iso_label}")
    iso_label="${iso_label:-SERIKAOS}"

    local releng="/usr/share/archiso/configs/releng"
    if [[ ! -d "$releng" ]]; then
        error "Archiso releng profile not found at ${releng}"
    fi

    # Copy essential releng directories we use as a base
    for dir in syslinux efiboot; do
        if [[ -d "${releng}/${dir}" ]]; then
            rm -rf "${PROFILE_DIR:?}/${dir}"
            log "Copying ${dir} from releng..."
            cp -r "${releng}/${dir}" "${PROFILE_DIR}/"
        fi
    done

    # Copy GRUB config from releng if we don't have one yet
    if [[ ! -d "${PROFILE_DIR}/grub" ]]; then
        cp -r "${releng}/grub" "${PROFILE_DIR}/"
    fi

    local airootfs="${PROFILE_DIR}/airootfs"

    # ── GRUB Theme ──
    log "Installing GRUB theme..."
    mkdir -p "${airootfs}/usr/share/grub/themes/SerikaOS"
    cp -r "${SCRIPT_DIR}/grub-theme/"* "${airootfs}/usr/share/grub/themes/SerikaOS/" 2>/dev/null || true
    # Don't include install script in airootfs
    rm -f "${airootfs}/usr/share/grub/themes/SerikaOS/install.sh"

    # ── SDDM Theme ──
    log "Installing SDDM theme..."
    mkdir -p "${airootfs}/usr/share/sddm/themes/SerikaOS"
    cp -r "${SCRIPT_DIR}/sddm-theme/"* "${airootfs}/usr/share/sddm/themes/SerikaOS/" 2>/dev/null || true

    # ── Wallpapers ──
    log "Installing wallpapers..."
    mkdir -p "${airootfs}/usr/share/wallpapers/SerikaOS"
    if [[ -d "${SCRIPT_DIR}/built-in-media/wallpapers" ]]; then
        cp -r "${SCRIPT_DIR}/built-in-media/wallpapers/"* "${airootfs}/usr/share/wallpapers/SerikaOS/" 2>/dev/null || true
    fi

    # Ensure SDDM background matches Serika wallpaper
    if [[ -f "${SCRIPT_DIR}/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg" ]]; then
        cp "${SCRIPT_DIR}/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg" \
            "${airootfs}/usr/share/sddm/themes/SerikaOS/Background.jpg"
    fi

    # ── SYSLINUX branding overlay ──
    log "Installing BIOS boot branding..."
    mkdir -p "${PROFILE_DIR}/syslinux"
    if [[ -d "${SCRIPT_DIR}/archiso-profile/syslinux" ]]; then
        cp -r "${SCRIPT_DIR}/archiso-profile/syslinux/"* "${PROFILE_DIR}/syslinux/" 2>/dev/null || true
    fi

    if command -v convert &>/dev/null && [[ -f "${SCRIPT_DIR}/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg" ]]; then
        convert "${SCRIPT_DIR}/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg" \
            -resize 640x480^ -gravity center -extent 640x480 \
            "${PROFILE_DIR}/syslinux/splash.png" 2>/dev/null || true
    fi

    cat > "${PROFILE_DIR}/syslinux/syslinux.cfg" << EOF
DEFAULT select

LABEL select
COM32 whichsys.c32
APPEND -pxe- pxe -sys- sys -iso- sys

LABEL pxe
CONFIG archiso_pxe.cfg

LABEL sys
CONFIG archiso_sys.cfg
EOF

    cat > "${PROFILE_DIR}/syslinux/archiso_head.cfg" << EOF
SERIAL 0 115200
UI vesamenu.c32
MENU TITLE SerikaOS
MENU BACKGROUND splash.png

MENU WIDTH 78
MENU MARGIN 4
MENU ROWS 7
MENU VSHIFT 10
MENU TABMSGROW 14
MENU CMDLINEROW 14
MENU HELPMSGROW 16
MENU HELPMSGENDROW 29

MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;35;44 #90e8a0bf #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std

MENU CLEAR
MENU IMMEDIATE
EOF

    cat > "${PROFILE_DIR}/syslinux/archiso_sys.cfg" << EOF
INCLUDE archiso_head.cfg

DEFAULT serika-live
TIMEOUT 40

INCLUDE archiso_sys-linux.cfg

INCLUDE archiso_tail.cfg
EOF

    cat > "${PROFILE_DIR}/syslinux/archiso_sys-linux.cfg" << EOF
LABEL serika-live
TEXT HELP
Boot the SerikaOS live environment on BIOS.
Use this to try SerikaOS or launch the installer.
ENDTEXT
MENU LABEL Try SerikaOS live medium (x86_64, BIOS)
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${iso_label} quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-install
TEXT HELP
Boot the SerikaOS installer environment on BIOS.
Use this to launch the graphical install flow.
ENDTEXT
MENU LABEL Install SerikaOS (x86_64, BIOS)
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${iso_label} systemd.unit=graphical.target quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-safe
TEXT HELP
Boot SerikaOS with safe graphics mode.
ENDTEXT
MENU LABEL SerikaOS safe graphics mode
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${iso_label} nomodeset quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
EOF

    cat > "${PROFILE_DIR}/syslinux/archiso_tail.cfg" << EOF
LABEL existing
TEXT HELP
Boot an existing operating system.
Press TAB to edit the disk and partition number to boot.
ENDTEXT
MENU LABEL Boot existing OS
COM32 chain.c32
APPEND hd0 0

LABEL memtest
MENU LABEL Run Memtest86+ (RAM test)
LINUX /boot/memtest86+/memtest

LABEL hdt
MENU LABEL Hardware Information (HDT)
COM32 hdt.c32
APPEND modules_alias=hdt/modalias.gz pciids=hdt/pciids.gz

LABEL reboot
TEXT HELP
Reboot computer.
ENDTEXT
MENU LABEL Reboot
COM32 reboot.c32

LABEL poweroff
TEXT HELP
Power off computer.
ENDTEXT
MENU LABEL Power Off
COM32 poweroff.c32
EOF

    # ── System Sounds ──
    log "Installing system sounds..."
    mkdir -p "${airootfs}/usr/share/sounds/SerikaOS"
    if [[ -d "${SCRIPT_DIR}/built-in-media/audio" ]]; then
        cp -r "${SCRIPT_DIR}/built-in-media/audio/"* "${airootfs}/usr/share/sounds/SerikaOS/" 2>/dev/null || true
    fi

    # ── ASCII Logo for fastfetch ──
    log "Installing ASCII logo..."
    mkdir -p "${airootfs}/usr/share/serikaos"
    if [[ -f "${SCRIPT_DIR}/branding/ascii-logo.txt" ]]; then
        cp "${SCRIPT_DIR}/branding/ascii-logo.txt" "${airootfs}/usr/share/serikaos/ascii-logo.txt"
    fi

    # ── Logo PNG ──
    if [[ -f "${SCRIPT_DIR}/built-in-media/logo/serikaos-logo.png" ]]; then
        cp "${SCRIPT_DIR}/built-in-media/logo/serikaos-logo.png" "${airootfs}/usr/share/serikaos/logo.png"
    fi

    # ── Boot logo asset (used by Plymouth customization in chroot) ──
    if command -v magick &>/dev/null; then
        magick -size 900x220 xc:none \
            -font DejaVu-Sans-Bold -pointsize 120 -fill white -gravity center -annotate -130+0 "Serika" \
            -font DejaVu-Sans-Bold -pointsize 120 -fill "#e8a0bf" -gravity center -annotate +260+0 "OS" \
            "${airootfs}/usr/share/serikaos/boot-logo.png" 2>/dev/null || true
    elif command -v convert &>/dev/null; then
        convert -size 900x220 xc:none \
            -font DejaVu-Sans-Bold -pointsize 120 -fill white -gravity center -annotate -130+0 "Serika" \
            -font DejaVu-Sans-Bold -pointsize 120 -fill "#e8a0bf" -gravity center -annotate +260+0 "OS" \
            "${airootfs}/usr/share/serikaos/boot-logo.png" 2>/dev/null || true
    fi

    # ── SDDM Configuration ──
    mkdir -p "${airootfs}/etc/sddm.conf.d"
    cat > "${airootfs}/etc/sddm.conf.d/serikaos.conf" << 'EOF'
[Theme]
Current=SerikaOS

[Autologin]
User=liveuser
Session=plasma.desktop
Relogin=false

[Users]
HideUsers=sddm,nobody,daemon,bin,sys,mail,ftp,http,dbus,polkitd,avahi,colord,git,rtkit,uuidd,ntp,systemd-journal-remote,systemd-network,systemd-oom,systemd-resolve,systemd-timesync,tss
HideShells=/usr/bin/nologin,/sbin/nologin,/bin/false
MinimumUid=1000
MaximumUid=65000
RememberLastUser=false
RememberLastSession=false
EOF

    # ── Deterministic live-user setup at build time (inside chroot) ──
    mkdir -p "${airootfs}/root"
    cat > "${airootfs}/root/customize_airootfs.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

groupadd -f autologin
id -u liveuser >/dev/null 2>&1 || useradd -m -u 1000 -G wheel,audio,video,optical,storage,network -s /bin/bash -c "SerikaOS Live User" liveuser
usermod -aG autologin liveuser

passwd -d liveuser || true
passwd -d root || true

printf "%s\n" "#%PAM-1.0" "auth     required pam_env.so" "auth     required pam_permit.so" "account  required pam_permit.so" "password required pam_deny.so" "session  required pam_limits.so" "session  optional pam_keyinit.so force revoke" "session  required pam_env.so" "session  required pam_permit.so" > /etc/pam.d/sddm-autologin
printf "%s\n" "#%PAM-1.0" "auth       sufficient   pam_unix.so nullok try_first_pass" "auth       required     pam_deny.so" "account    required     pam_permit.so" "password   required     pam_deny.so" "session    required     pam_limits.so" "session    optional     pam_keyinit.so force revoke" "session    required     pam_env.so" "session    required     pam_unix.so" > /etc/pam.d/sddm

mkdir -p /etc/sudoers.d
echo "root ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/00-live
echo "liveuser ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/00-live
chmod 440 /etc/sudoers.d/00-live

mkdir -p /home/liveuser/Desktop
cp -a /etc/skel/. /home/liveuser/ 2>/dev/null || true
chown -R liveuser:liveuser /home/liveuser

# Polkit rule to allow liveuser to run Calamares without password
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/49-nopasswd-calamares.rules << 'POLKITEOF'
polkit.addRule(function(action, subject) {
    if (subject.user == "liveuser") {
        return polkit.Result.YES;
    }
});
POLKITEOF

cat > /home/liveuser/.bash_profile << 'BASHEOF'
if [[ -z "${DISPLAY:-}" && "$(tty)" == "/dev/tty1" ]]; then
    exec startx
fi
BASHEOF

cat > /home/liveuser/.xinitrc << 'XINITEOF'
#!/bin/sh
export QT_QPA_PLATFORM=xcb
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_ENABLE_HIGHDPI_SCALING=0
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export GDK_DPI_SCALE=1

# VM detection — use lighter settings but keep GPU acceleration
if [ -r /sys/class/dmi/id/product_name ] && grep -Eiq 'kvm|qemu|virtualbox|vmware' /sys/class/dmi/id/product_name 2>/dev/null; then
    export KWIN_LOWLATENCY=1
    # Write a lighter kwin config for VMs
    mkdir -p "$HOME/.config"
    kwriteconfig5 --file kwinrc --group Compositing --key Backend XRender 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled true 2>/dev/null || true
    kwriteconfig5 --file kwinrc --group "Effect-Blur" --key Enabled false 2>/dev/null || true
fi

exec dbus-run-session startplasma-x11
XINITEOF

chmod +x /home/liveuser/.xinitrc
chown liveuser:liveuser /home/liveuser/.bash_profile /home/liveuser/.xinitrc

cat > /etc/profile.d/serikaos-scale.sh << 'SCALEEOF'
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_ENABLE_HIGHDPI_SCALING=0
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export GDK_DPI_SCALE=1
SCALEEOF
chmod 755 /etc/profile.d/serikaos-scale.sh

cat > /etc/environment << 'ENVEOF'
QT_AUTO_SCREEN_SCALE_FACTOR=0
QT_ENABLE_HIGHDPI_SCALING=0
QT_SCALE_FACTOR=1
GDK_SCALE=1
GDK_DPI_SCALE=1
ENVEOF

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme spinner >/dev/null 2>&1 || true
fi

mkdir -p /etc/plymouth /usr/share/plymouth/themes/spinner
cat > /etc/plymouth/plymouthd.conf << 'PLYEOF'
[Daemon]
Theme=spinner
ShowDelay=0
DeviceTimeout=8
PLYEOF

if [[ -f /usr/share/serikaos/boot-logo.png ]]; then
    cp /usr/share/serikaos/boot-logo.png /usr/share/plymouth/themes/spinner/watermark.png
elif [[ -f /usr/share/serikaos/logo.png ]]; then
    cp /usr/share/serikaos/logo.png /usr/share/plymouth/themes/spinner/watermark.png
fi
EOF
    chmod +x "${airootfs}/root/customize_airootfs.sh"

    # ── Live session auto-login (TTY fallback) ──
    mkdir -p "${airootfs}/etc/systemd/system/getty@tty1.service.d"
    cat > "${airootfs}/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin liveuser --noclear %I 38400 linux
EOF

    # ── Enable essential services ──
    mkdir -p "${airootfs}/etc/systemd/system/multi-user.target.wants"
    mkdir -p "${airootfs}/etc/systemd/system/graphical.target.wants"

    # Live mode boots via tty autologin + startx; do not force a display manager symlink.
    rm -f "${airootfs}/etc/systemd/system/display-manager.service" 2>/dev/null || true

    # Enable NetworkManager
    ln -sf /usr/lib/systemd/system/NetworkManager.service \
        "${airootfs}/etc/systemd/system/multi-user.target.wants/NetworkManager.service" 2>/dev/null || true

    # ── Sudoers for live session ──
    mkdir -p "${airootfs}/etc/sudoers.d"
    echo "root ALL=(ALL:ALL) NOPASSWD: ALL" > "${airootfs}/etc/sudoers.d/00-live"
    echo 'liveuser ALL=(ALL:ALL) NOPASSWD: ALL' >> "${airootfs}/etc/sudoers.d/00-live"
    chmod 440 "${airootfs}/etc/sudoers.d/00-live"

    # ── Desktop shortcuts (for both root and liveuser) ──
    mkdir -p "${airootfs}/root/Desktop"
    mkdir -p "${airootfs}/etc/skel/Desktop"
    cat > "${airootfs}/etc/skel/Desktop/install-serikaos.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Install SerikaOS
Comment=Launch the SerikaOS installer
Exec=/usr/local/bin/serikaos-installer
Icon=system-software-install
Terminal=true
Categories=System;
StartupNotify=true
SingleMainWindow=true
EOF
    chmod +x "${airootfs}/etc/skel/Desktop/install-serikaos.desktop"
    cp "${airootfs}/etc/skel/Desktop/install-serikaos.desktop" "${airootfs}/root/Desktop/" 2>/dev/null || true
    chmod +x "${airootfs}/root/Desktop/install-serikaos.desktop"

    # ── Root shell welcome ──
    mkdir -p "${airootfs}/root"
    # Only add welcome if not already present
    for rc in .bashrc .zshrc; do
        local rcfile="${airootfs}/root/${rc}"
        if [[ ! -f "$rcfile" ]] || ! grep -q "serikaos-welcome" "$rcfile" 2>/dev/null; then
            echo '# SerikaOS: show welcome on first login' >> "$rcfile"
            echo '[[ -z "$SERIKAOS_WELCOMED" ]] && export SERIKAOS_WELCOMED=1 && fastfetch 2>/dev/null' >> "$rcfile"
        fi
    done

    # ── System-wide wallpaper setter for live Plasma ──
    mkdir -p "${airootfs}/etc/xdg/autostart" "${airootfs}/usr/local/bin"
    cat > "${airootfs}/usr/local/bin/serikaos-apply-wallpaper" << 'EOF'
#!/bin/bash
set -e

WALLPAPER="/usr/share/wallpapers/SerikaOS/serika-pack-v1/wallpaper-1.jpg"

if [[ ! -f "$WALLPAPER" ]]; then
    exit 0
fi

if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$WALLPAPER" >/dev/null 2>&1 || true
fi
EOF
    chmod +x "${airootfs}/usr/local/bin/serikaos-apply-wallpaper"

    cat > "${airootfs}/etc/xdg/autostart/serikaos-apply-wallpaper.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Apply SerikaOS Wallpaper
Exec=/usr/local/bin/serikaos-apply-wallpaper
OnlyShowIn=KDE;
X-KDE-AutostartPhase=1
NoDisplay=true
EOF

    # ── Custom GRUB config for the ISO boot menu ──
    log "Configuring ISO boot menu..."
    mkdir -p "${PROFILE_DIR}/grub"
    cat > "${PROFILE_DIR}/grub/grub.cfg" << GRUBEOF
# SerikaOS — GRUB Boot Menu
insmod all_video
insmod gfxterm
insmod gfxmenu
insmod png
insmod jpeg

set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

# Load SerikaOS theme
set theme=(\${root})/boot/grub/themes/SerikaOS/theme.txt

set default=0
set timeout=3

menuentry '  Try SerikaOS — Live Session' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${iso_label} cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

menuentry '  Install SerikaOS' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${iso_label} cow_spacesize=2G systemd.unit=graphical.target quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

submenu '  Advanced Options >' --class submenu {
    menuentry '  SerikaOS (Safe Graphics — nomodeset)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${iso_label} nomodeset cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
        initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
    }
    menuentry '  SerikaOS (Copy to RAM)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${iso_label} copytoram cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
        initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
    }
    menuentry '  Boot from local disk' --class hd {
        exit
    }
}

menuentry '  Reboot' --class restart {
    reboot
}

menuentry '  Shut Down' --class shutdown {
    halt
}
GRUBEOF

    # Copy GRUB theme to ISO grub dir too
    mkdir -p "${PROFILE_DIR}/grub/themes/SerikaOS"
    cp -r "${SCRIPT_DIR}/grub-theme/"* "${PROFILE_DIR}/grub/themes/SerikaOS/" 2>/dev/null || true
    rm -f "${PROFILE_DIR}/grub/themes/SerikaOS/install.sh"

    success "Profile prepared."
}

# --- Build ISO ---
build_iso() {
    log "Building SerikaOS ISO..."
    log "This will take several minutes — go grab some coffee ☕"
    echo ""

    # Clean previous build
    if [[ -d "$WORK_DIR" ]]; then
        warn "Cleaning previous build artifacts..."
        rm -rf "$WORK_DIR"
    fi

    mkdir -p "$OUT_DIR"

    # Run mkarchiso
    mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

    echo ""
    local iso_file
    iso_file=$(ls -1t "${OUT_DIR}"/serikaos-*.iso 2>/dev/null | head -1)

    if [[ -n "$iso_file" ]] && [[ -f "$iso_file" ]]; then
        echo ""
        success "ISO built successfully!"
        echo ""
        log "File: ${iso_file}"
        log "Size: $(du -h "$iso_file" | cut -f1)"
        echo ""
        echo -e "${DIM}Test in QEMU:${RESET}"
        echo -e "  ${DIM}qemu-system-x86_64 -boot d -cdrom ${iso_file} -m 4G -enable-kvm${RESET}"
        echo ""
        echo -e "${DIM}Write to USB:${RESET}"
        echo -e "  ${DIM}sudo dd bs=4M if=${iso_file} of=/dev/sdX status=progress oflag=sync${RESET}"
    else
        error "ISO build failed — no output file found"
    fi
    echo ""
}

# --- Clean ---
clean() {
    log "Cleaning build artifacts..."
    rm -rf "$WORK_DIR"
    # Also clean copied releng dirs
    for dir in syslinux efiboot grub; do
        rm -rf "${PROFILE_DIR:?}/${dir}"
    done
    # Clean generated files in airootfs
    rm -rf "${PROFILE_DIR}/airootfs/usr/share/grub/themes/SerikaOS"
    rm -rf "${PROFILE_DIR}/airootfs/usr/share/sddm/themes/SerikaOS"
    rm -rf "${PROFILE_DIR}/airootfs/usr/share/wallpapers/SerikaOS"
    rm -rf "${PROFILE_DIR}/airootfs/usr/share/sounds/SerikaOS"
    rm -rf "${PROFILE_DIR}/airootfs/usr/share/serikaos"
    rm -rf "${PROFILE_DIR}/airootfs/etc/sddm.conf.d"
    rm -rf "${PROFILE_DIR}/airootfs/etc/systemd/system/getty@tty1.service.d"
    rm -rf "${PROFILE_DIR}/airootfs/etc/sudoers.d"
    rm -f "${PROFILE_DIR}/airootfs/etc/systemd/system/display-manager.service"
    rm -f "${PROFILE_DIR}/airootfs/root/Desktop/install-serikaos.desktop"
    success "Clean complete."
}

# --- Main ---
banner

case "${1:-build}" in
    build)
        preflight
        prepare_profile
        build_iso
        ;;
    clean)
        clean
        ;;
    prepare)
        preflight
        prepare_profile
        success "Profile prepared. Run 'build' to create ISO."
        ;;
    *)
        echo "Usage: sudo bash build.sh [build|clean|prepare]"
        echo ""
        echo "  build    — Build the SerikaOS ISO (default)"
        echo "  clean    — Remove all build artifacts"
        echo "  prepare  — Prepare profile without building"
        exit 1
        ;;
esac
