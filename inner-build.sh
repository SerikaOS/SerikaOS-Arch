#!/bin/bash
# ============================================================
# SerikaOS — Inner Build Script (runs INSIDE Docker container)
# This is called by build-docker-iso.sh — do not run directly.
# ============================================================

set -euo pipefail

echo "════════════════════════════════════════════════════════"
echo "  SerikaOS — Building inside Arch Linux container"
echo "════════════════════════════════════════════════════════"
echo ""

# --- 1. Install dependencies ---
echo "[*] Installing build dependencies..."
pacman -Sy --noconfirm archiso grub ttf-dejavu imagemagick base-devel git wget >/dev/null 2>&1

# --- 2. Build Calamares from AUR (pure Arch, no third-party repos) ---
pacman-key --init
pacman -S --noconfirm --needed base-devel git >/dev/null 2>&1

# Create a non-root build user
useradd -m builduser 2>/dev/null || true
echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser
chown -R builduser:builduser /home/builduser

# Check if we already have the packages cached (speeds up rebuilds)
if ls /serikaos-repo/calamares-*.pkg.tar.zst &>/dev/null && \
   ls /serikaos-repo/ckbcomp-*.pkg.tar.zst &>/dev/null; then
    echo "[*] AUR packages found in local repo cache, skipping build phase."
else
    echo "[*] Building Calamares from AUR..."
    # Install yay
    sudo -u builduser bash -c '
        cd /home/builduser
        if [[ ! -d yay-bin ]]; then
            git clone https://aur.archlinux.org/yay-bin.git
        fi
        cd yay-bin && makepkg -si --noconfirm
    '

    # Build calamares and dependencies from AUR
    mkdir -p /home/builduser/build
    chown builduser:builduser /home/builduser/build
    sudo -u builduser bash -c '
        yay -S --noconfirm calamares ckbcomp qt5-xmlpatterns
    '

    # Create local repo from built packages
    echo "[*] Creating local SerikaOS package repository..."
    mkdir -p /serikaos-repo
    find /home/builduser/.cache/yay -name "*.pkg.tar.zst" -exec cp {} /serikaos-repo/ \;
fi

# Refresh local repo index
if ls /serikaos-repo/*.pkg.tar.zst &>/dev/null; then
    echo "[*] Refreshing local repository index..."
    repo-add /serikaos-repo/serikaos-local.db.tar.gz /serikaos-repo/*.pkg.tar.zst
    ln -sf serikaos-local.db.tar.gz /serikaos-repo/serikaos-local.db
    ln -sf serikaos-local.files.tar.gz /serikaos-repo/serikaos-local.files
fi

# --- 3. Copy releng base profile ---
PROFILE_DIR="${SERIKA_PROFILE_DIR:-/tmp/serikaos-profile}"
if [ -d "$PROFILE_DIR" ]; then
    find "$PROFILE_DIR" -mindepth 1 -delete
else
    mkdir -p "$PROFILE_DIR"
fi
cp -a /usr/share/archiso/configs/releng/. "$PROFILE_DIR/"

# --- 4. Use our pacman.conf and append local repo ---
cp /serikaos/archiso-profile/pacman.conf "$PROFILE_DIR/pacman.conf"

cat >> "$PROFILE_DIR/pacman.conf" << EOF

[serikaos-local]
SigLevel = Optional TrustAll
Server = file:///serikaos-repo
EOF

# --- 5. Optimize mkinitcpio for ISO (Add Plymouth, remove PXE) ---
echo "[*] Optimizing initramfs hooks..."
mkdir -p "$PROFILE_DIR/airootfs/etc/mkinitcpio.conf.d"
cat > "$PROFILE_DIR/airootfs/etc/mkinitcpio.conf.d/archiso.conf" << EOF
HOOKS=(base udev plymouth microcode modconf kms memdisk archiso archiso_loop_mnt block filesystems keyboard)
EOF



# --- 5. Replace package list with our minimal one ---
echo "[*] Setting up minimal package list..."
cp /serikaos/archiso-profile/packages.x86_64 "$PROFILE_DIR/packages.x86_64"

# --- 6. Profile definition ---
cat > "$PROFILE_DIR/profiledef.sh" << PROFILEDEF
#!/usr/bin/env bash
iso_name="serikaos"
iso_label="${ISO_LABEL:-SERIKAOS_$(date +%Y%m)}"
iso_publisher="SerikaOS"
iso_application="SerikaOS Live/Install Medium"
iso_version="${ISO_VERSION:-$(date +%Y.%m.%d)}"
install_dir="arch"
buildmodes=("iso")
bootmodes=(
    "bios.syslinux.mbr"
    "bios.syslinux.eltorito"
    "uefi-ia32.grub.esp"
    "uefi-x64.grub.esp"
    "uefi-ia32.grub.eltorito"
    "uefi-x64.grub.eltorito"
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=("-comp" "zstd" "-Xcompression-level" "3" "-b" "1M")
file_permissions=(
    ["/etc/shadow"]="0:0:400"
    ["/etc/gshadow"]="0:0:400"
    ["/etc/sudoers.d/00-live"]="0:0:440"
    ["/usr/local/bin/serikaos-installer"]="0:0:755"
    ["/usr/local/bin/serikaos-welcome"]="0:0:755"
)
PROFILEDEF

# --- 6. Stage SerikaOS customizations ---
echo "[*] Staging SerikaOS customizations..."

AIROOTFS="$PROFILE_DIR/airootfs"
STAGING="$AIROOTFS/opt/serikaos-custom"
mkdir -p "$STAGING/etc/calamares/branding/serikaos"
mkdir -p "$STAGING/etc/calamares/modules"
mkdir -p "$STAGING/usr/local/bin"
mkdir -p "$STAGING/usr/share/grub/themes/SerikaOS"

# Calamares config
cp /serikaos/archiso-profile/airootfs/etc/calamares/settings.conf "$STAGING/etc/calamares/" 2>/dev/null || true
cp /serikaos/archiso-profile/airootfs/etc/calamares/branding/serikaos/* "$STAGING/etc/calamares/branding/serikaos/" 2>/dev/null || true
cp /serikaos/archiso-profile/airootfs/etc/calamares/modules/* "$STAGING/etc/calamares/modules/" 2>/dev/null || true

# OS branding files (hostname, hosts, etc.)
for f in hostname hosts locale.conf locale.gen issue; do
    if [[ -f "/serikaos/archiso-profile/airootfs/etc/${f}" ]]; then
        cp "/serikaos/archiso-profile/airootfs/etc/${f}" "$STAGING/etc/${f}"
    fi
done

# Executable scripts
for script in serikaos-installer serikaos-welcome; do
    if [[ -f "/serikaos/archiso-profile/airootfs/usr/local/bin/${script}" ]]; then
        cp "/serikaos/archiso-profile/airootfs/usr/local/bin/${script}" "$STAGING/usr/local/bin/"
    fi
done

# Desktop entries
mkdir -p "$STAGING/usr/share/applications"
cp /serikaos/archiso-profile/airootfs/usr/share/applications/*.desktop "$STAGING/usr/share/applications/" 2>/dev/null || true

# Skel configs
if [[ -d "/serikaos/archiso-profile/airootfs/etc/skel" ]]; then
    cp -r /serikaos/archiso-profile/airootfs/etc/skel "$STAGING/etc/"
fi

# Systemd services
if [[ -d "/serikaos/archiso-profile/airootfs/etc/systemd" ]]; then
    cp -r /serikaos/archiso-profile/airootfs/etc/systemd "$STAGING/etc/"
fi

# GRUB theme
THEME_DIR="$STAGING/usr/share/grub/themes/SerikaOS"
cp -r /serikaos/grub-theme/* "$THEME_DIR/" 2>/dev/null || true
rm -f "$THEME_DIR/install.sh"



# Generate PF2 fonts
if [[ -f /usr/share/fonts/TTF/DejaVuSans.ttf ]]; then
    mkdir -p "$THEME_DIR/fonts"
    grub-mkfont -s 11 -o "$THEME_DIR/fonts/dejavu_11.pf2" /usr/share/fonts/TTF/DejaVuSans.ttf
    grub-mkfont -s 12 -o "$THEME_DIR/fonts/dejavu_12.pf2" /usr/share/fonts/TTF/DejaVuSans.ttf
    grub-mkfont -s 14 -o "$THEME_DIR/fonts/dejavu_14.pf2" /usr/share/fonts/TTF/DejaVuSans.ttf
    grub-mkfont -s 16 -o "$THEME_DIR/fonts/dejavu_16.pf2" /usr/share/fonts/TTF/DejaVuSans.ttf
    grub-mkfont -s 24 -o "$THEME_DIR/fonts/dejavu_24.pf2" /usr/share/fonts/TTF/DejaVuSans.ttf
fi
if [[ -f /usr/share/fonts/TTF/DejaVuSans-Bold.ttf ]]; then
    grub-mkfont -s 16 -o "$THEME_DIR/fonts/dejavu_bold_16.pf2" /usr/share/fonts/TTF/DejaVuSans-Bold.ttf
    grub-mkfont -s 24 -o "$THEME_DIR/fonts/dejavu_bold_24.pf2" /usr/share/fonts/TTF/DejaVuSans-Bold.ttf
fi

# Copy theme into ISO boot grub dir
mkdir -p "$PROFILE_DIR/grub/themes/SerikaOS"
cp -r "$THEME_DIR/"* "$PROFILE_DIR/grub/themes/SerikaOS/"
# Also copy fonts to the actual grub fonts dir so they can be loaded before the theme
mkdir -p "$PROFILE_DIR/grub/fonts"
cp "$THEME_DIR/fonts/"*.pf2 "$PROFILE_DIR/grub/fonts/" 2>/dev/null || true

# --- 8. SDDM theme ---
echo "[*] Installing SDDM theme..."
mkdir -p "$AIROOTFS/usr/share/sddm/themes/SerikaOS"
cp -r /serikaos/sddm-theme/* "$AIROOTFS/usr/share/sddm/themes/SerikaOS/" 2>/dev/null || true
if [[ -f "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Logo.png" ]]; then
    magick "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Logo.png" -resize 600x "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Logo.png" 2>/dev/null || true
fi

# --- 9. Wallpapers & media ---
echo "[*] Installing media assets..."
mkdir -p "$AIROOTFS/usr/share/wallpapers/SerikaOS"
cp -r /serikaos/built-in-media/wallpapers/* "$AIROOTFS/usr/share/wallpapers/SerikaOS/" 2>/dev/null || true

if [[ -f /serikaos/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg ]]; then
    cp /serikaos/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg \
        "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Background.jpg"
fi

mkdir -p "$AIROOTFS/usr/share/sounds/SerikaOS"
cp -r /serikaos/built-in-media/audio/* "$AIROOTFS/usr/share/sounds/SerikaOS/" 2>/dev/null || true

# ASCII logo for fastfetch
mkdir -p "$AIROOTFS/usr/share/serikaos"
cp /serikaos/branding/ascii-logo.txt "$AIROOTFS/usr/share/serikaos/" 2>/dev/null || true
cp /serikaos/built-in-media/logo/serikaos-logo.png "$AIROOTFS/usr/share/serikaos/logo.png" 2>/dev/null || true

# Boot logo asset (used by Plymouth and SDDM)
LOGO_TEXT="/serikaos/built-in-media/logo/SerikaOS-LogoText.png"
mkdir -p "$AIROOTFS/usr/share/serikaos"
mkdir -p "$AIROOTFS/usr/share/plymouth/themes/serika"

if [[ -f "$LOGO_TEXT" ]]; then
    # Plymouth logo (needs to be smaller)
    magick "$LOGO_TEXT" -resize 450x "$AIROOTFS/usr/share/plymouth/themes/serika/watermark.png" 2>/dev/null || true
    # Global boot logo for firstboot backup
    cp "$LOGO_TEXT" "$AIROOTFS/usr/share/serikaos/boot-logo.png"
elif command -v magick &>/dev/null; then
    magick -size 900x220 xc:none \
        -font DejaVu-Sans-Bold -pointsize 120 -fill white -gravity center -annotate -130+0 "Serika" \
        -font DejaVu-Sans-Bold -pointsize 120 -fill "#e8a0bf" -gravity center -annotate +260+0 "OS" \
        -resize 450x "$AIROOTFS/usr/share/plymouth/themes/serika/watermark.png" 2>/dev/null || true
fi

# Define custom Plymouth theme (prevents conflicts with spinner)
cat > "$AIROOTFS/usr/share/plymouth/themes/serika/serika.plymouth" << 'EOF'
[Plymouth Theme]
Name=SerikaOS
Description=SerikaOS spinner theme
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/serika
HorizontalAlignment=0.5
VerticalAlignment=0.5
Transition=fade
TransitionDuration=0.5

[spinner]
Watermark=watermark.png
EOF

# NOTE: Plymouth/pixmap overrides happen INSIDE customize_airootfs.sh (after pacman)
# to avoid conflicting with the filesystem and plymouth packages.

# --- 9.5. SYSLINUX branding overlay ---
echo "[*] Installing BIOS boot branding..."
mkdir -p "$PROFILE_DIR/syslinux"
cp -r /usr/share/archiso/configs/releng/syslinux/* "$PROFILE_DIR/syslinux/" 2>/dev/null || true
cp -r /serikaos/archiso-profile/syslinux/* "$PROFILE_DIR/syslinux/" 2>/dev/null || true

if [[ -f /serikaos/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg ]]; then
    magick /serikaos/built-in-media/wallpapers/serika-pack-v1/wallpaper-1.jpg \
        -resize 640x480^ -gravity center -extent 640x480 \
        "$PROFILE_DIR/syslinux/splash.png" 2>/dev/null || true
fi

cat > "$PROFILE_DIR/syslinux/syslinux.cfg" << EOF
DEFAULT select

LABEL select
COM32 whichsys.c32
APPEND -pxe- pxe -sys- sys -iso- sys

LABEL pxe
CONFIG archiso_pxe.cfg

LABEL sys
CONFIG archiso_sys.cfg
EOF

cat > "$PROFILE_DIR/syslinux/archiso_head.cfg" << EOF
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

cat > "$PROFILE_DIR/syslinux/archiso_sys.cfg" << EOF
INCLUDE archiso_head.cfg

DEFAULT serika-live
TIMEOUT 40

INCLUDE archiso_sys-linux.cfg

INCLUDE archiso_tail.cfg
EOF

cat > "$PROFILE_DIR/syslinux/archiso_sys-linux.cfg" << EOF
LABEL serika-live
TEXT HELP
Boot the SerikaOS live environment on BIOS.
Use this to try SerikaOS or launch the installer.
ENDTEXT
MENU LABEL Try SerikaOS live medium (x86_64, BIOS)
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-install
TEXT HELP
Boot the SerikaOS installer environment on BIOS.
Use this to launch the graphical install flow.
ENDTEXT
MENU LABEL Install SerikaOS (x86_64, BIOS)
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} systemd.unit=graphical.target quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-safe
TEXT HELP
Boot SerikaOS with safe graphics mode.
ENDTEXT
MENU LABEL SerikaOS safe graphics mode
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} nomodeset quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
EOF

cat > "$PROFILE_DIR/syslinux/archiso_tail.cfg" << EOF
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

# --- 10. Generate branding images for Calamares ---
echo "[*] Generating installer branding images..."
BRANDING_DIR="$AIROOTFS/etc/calamares/branding/serikaos"

LOGO_SRC="/serikaos/built-in-media/logo/serikaos-logo.png"
WALL_SRC="/serikaos/built-in-media/wallpapers/boot.jpg"

if command -v magick &>/dev/null; then
    if [[ -f "$LOGO_SRC" ]]; then
        magick "$LOGO_SRC" -resize 128x128 "$BRANDING_DIR/logo.png" 2>/dev/null || true
    fi
    if [[ -f "$WALL_SRC" ]]; then
        magick "$WALL_SRC" -resize 1920x1080^ -gravity center -extent 1920x1080 "$BRANDING_DIR/wallpaper.png" 2>/dev/null || true
        magick "$WALL_SRC" -resize 800x450 "$BRANDING_DIR/welcome.png" 2>/dev/null || true
    fi
fi



# ============================================================
# STATIC AIROOTFS CUSTOMIZATIONS
# Modern archiso no longer runs customize_airootfs.sh.
# All customization must be done via static files in airootfs
# plus a first-boot systemd service for runtime operations.
# ============================================================

echo "[*] Writing static airootfs configuration..."

# --- graphical.target as default (THIS IS THE KEY TO AVOIDING BLACK SCREEN) ---
mkdir -p "$AIROOTFS/etc/systemd/system"
ln -sf /usr/lib/systemd/system/graphical.target "$AIROOTFS/etc/systemd/system/default.target"

# --- SDDM autologin config (static, using plasma.desktop for Plasma 6 Wayland) ---
mkdir -p "$AIROOTFS/etc/sddm.conf.d"
cat > "$AIROOTFS/etc/sddm.conf.d/autologin.conf" << 'SDDMCFGEOF'
[Autologin]
User=liveuser
Session=plasma.desktop
Relogin=false

[Theme]
Current=SerikaOS

[Users]
MinimumUid=1000
MaximumUid=65000
RememberLastUser=false
RememberLastSession=false
SDDMCFGEOF

# --- PAM: SDDM autologin ---
mkdir -p "$STAGING/etc/pam.d"
cat > "$STAGING/etc/pam.d/sddm-autologin" << 'PAMEOF'
#%PAM-1.0
auth     required pam_env.so
auth     required pam_permit.so
account  required pam_permit.so
password required pam_deny.so
session  required pam_limits.so
session  optional pam_keyinit.so force revoke
session  required pam_env.so
session  required pam_permit.so
PAMEOF

cat > "$STAGING/etc/pam.d/sddm" << 'PAMEOF2'
#%PAM-1.0
auth       sufficient   pam_unix.so nullok try_first_pass
auth       required     pam_deny.so
account    required     pam_permit.so
password   required     pam_deny.so
session    required     pam_limits.so
session    optional     pam_keyinit.so force revoke
session    required     pam_env.so
session    required     pam_unix.so
PAMEOF2

# --- Sudoers ---
mkdir -p "$AIROOTFS/etc/sudoers.d"
cat > "$AIROOTFS/etc/sudoers.d/00-live" << 'SUDOEOF'
root ALL=(ALL:ALL) NOPASSWD: ALL
liveuser ALL=(ALL:ALL) NOPASSWD: ALL
SUDOEOF

# --- Polkit: allow liveuser to do everything ---
mkdir -p "$AIROOTFS/etc/polkit-1/rules.d"
cat > "$AIROOTFS/etc/polkit-1/rules.d/49-nopasswd-calamares.rules" << 'POLKITEOF'
polkit.addRule(function(action, subject) {
    if (subject.user == "liveuser") {
        return polkit.Result.YES;
    }
});
POLKITEOF

# --- OS branding ---
cat > "$STAGING/etc/os-release" << 'OSREOF'
NAME="SerikaOS"
PRETTY_NAME="SerikaOS"
ID=serikaos
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;232;160;191"
HOME_URL="https://github.com/serikaos"
DOCUMENTATION_URL="https://wiki.archlinux.org"
SUPPORT_URL="https://github.com/serikaos/issues"
BUG_REPORT_URL="https://github.com/serikaos/issues"
PRIVACY_POLICY_URL="https://github.com/serikaos"
LOGO=serikaos
OSREOF

cat > "$STAGING/etc/lsb-release" << 'LSBREOF'
DISTRIB_ID=SerikaOS
DISTRIB_RELEASE=rolling
DISTRIB_DESCRIPTION="SerikaOS Rolling platform"
DISTRIB_CODENAME=serika
LSBREOF

# --- Environment variables ---
cat > "$STAGING/etc/environment" << 'ENVEOF'
QT_AUTO_SCREEN_SCALE_FACTOR=0
QT_ENABLE_HIGHDPI_SCALING=0
QT_SCALE_FACTOR=1
GDK_SCALE=1
GDK_DPI_SCALE=1
KWIN_X11_NO_SYNC_TO_VBLANK=1
KWIN_LOWLATENCY=1
KWIN_EFFECTS_FOR_LOW_PERFORMANCE=1
ENVEOF

mkdir -p "$AIROOTFS/etc/profile.d"
cat > "$AIROOTFS/etc/profile.d/serikaos-scale.sh" << 'SCALEEOF'
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_ENABLE_HIGHDPI_SCALING=0
export QT_SCALE_FACTOR=1
export GDK_SCALE=1
export GDK_DPI_SCALE=1
SCALEEOF

# --- Plymouth config (moved back to AIROOTFS to ensure it's in initramfs) ---
mkdir -p "$AIROOTFS/etc/plymouth"
cat > "$AIROOTFS/etc/plymouth/plymouthd.conf" << 'PLYEOF'
[Daemon]
Theme=serika
ShowDelay=0
DeviceTimeout=8
PLYEOF

# --- liveuser via sysusers.d (avoids passwd conflicts) ---
mkdir -p "$AIROOTFS/etc/sysusers.d"
cat > "$AIROOTFS/etc/sysusers.d/liveuser.conf" << 'SYSUSEREOF'
u liveuser 1000 "SerikaOS Live User" /home/liveuser /bin/bash
m liveuser wheel
m liveuser audio
m liveuser video
m liveuser optical
m liveuser storage
m liveuser network
m liveuser autologin
SYSUSEREOF

# Keep staging shadow/gshadow for initial permission setup
mkdir -p "$STAGING/etc"
cat > "$STAGING/etc/shadow" << 'SHEOF'
root::14871::::::
liveuser::14871:0:99999:7:::
SHEOF

cat > "$STAGING/etc/gshadow" << 'GSHEOF'
root:::
wheel:::liveuser
audio:::liveuser
video:::liveuser
optical:::liveuser
storage:::liveuser
network:::liveuser
autologin:::liveuser
liveuser:!::
GSHEOF

# --- Desktop shortcut in skel ---
mkdir -p "$AIROOTFS/etc/skel/Desktop"
cat > "$AIROOTFS/etc/skel/Desktop/install-serikaos.desktop" << 'DESKEOF'
[Desktop Entry]
Type=Application
Name=Install SerikaOS
Comment=Launch the SerikaOS installer
Exec=/usr/local/bin/serikaos-installer
Icon=system-software-install
Terminal=false
Categories=System;
StartupNotify=true
SingleMainWindow=true
DESKEOF

# --- First-boot service (runtime-only operations) ---
mkdir -p "$AIROOTFS/usr/local/bin"
cat > "$AIROOTFS/usr/local/bin/serikaos-firstboot" << 'FBEOF'
#!/bin/bash
set -e

# Ensure liveuser home exists with skel content
if [[ ! -d /home/liveuser ]]; then
    mkdir -p /home/liveuser
fi
cp -a /etc/skel/. /home/liveuser/ 2>/dev/null || true
mkdir -p /home/liveuser/Desktop
cp /usr/share/applications/serikaos-installer.desktop /home/liveuser/Desktop/ 2>/dev/null || true
cp /etc/skel/Desktop/install-serikaos.desktop /home/liveuser/Desktop/ 2>/dev/null || true
chmod +x /home/liveuser/Desktop/*.desktop 2>/dev/null || true
chown -R 1000:1000 /home/liveuser

# Trust desktop files for KDE
mkdir -p /home/liveuser/.local/share
cat > /home/liveuser/.local/share/trusted-desktop-files << 'TRUSTEOF'
/home/liveuser/Desktop/install-serikaos.desktop
/home/liveuser/Desktop/serikaos-installer.desktop
TRUSTEOF
chown -R 1000:1000 /home/liveuser/.local

# Overwrite branding (backup/fallback branding)
if [[ -f /usr/share/serikaos/boot-logo.png ]]; then
    cp /usr/share/serikaos/boot-logo.png /usr/share/pixmaps/archlinux-logo.png 2>/dev/null || true
    cp /usr/share/serikaos/boot-logo.png /usr/share/pixmaps/archlinux-logo-text.png 2>/dev/null || true
elif [[ -f /usr/share/serikaos/logo.png ]]; then
    cp /usr/share/serikaos/logo.png /usr/share/pixmaps/archlinux-logo.png 2>/dev/null || true
fi

# Apply staged customizations
if [[ -d /opt/serikaos-custom ]]; then
    cp -a /opt/serikaos-custom/* /
    rm -rf /opt/serikaos-custom
fi

chmod +x /usr/local/bin/serikaos-installer /usr/local/bin/serikaos-welcome 2>/dev/null || true
FBEOF
chmod +x "$AIROOTFS/usr/local/bin/serikaos-firstboot"

mkdir -p "$AIROOTFS/etc/systemd/system"
cat > "$AIROOTFS/etc/systemd/system/serikaos-firstboot.service" << 'SVCEOF'
[Unit]
Description=SerikaOS First Boot Setup
After=local-fs.target
Before=sddm.service display-manager.service
ConditionPathExists=!/var/lib/serikaos-firstboot-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/serikaos-firstboot
ExecStartPost=/usr/bin/touch /var/lib/serikaos-firstboot-done
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVCEOF

# Enable firstboot service
mkdir -p "$AIROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/serikaos-firstboot.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/serikaos-firstboot.service"

# --- Root bashrc ---
mkdir -p "$AIROOTFS/root"
cat >> "$AIROOTFS/root/.bashrc" << 'BASHEOF'
# SerikaOS live session
[[ -z "$SERIKAOS_WELCOMED" ]] && export SERIKAOS_WELCOMED=1 && fastfetch 2>/dev/null
BASHEOF

# Enable SDDM via symlink (belt and suspenders)
mkdir -p "$AIROOTFS/etc/systemd/system"
ln -sf /usr/lib/systemd/system/sddm.service "$AIROOTFS/etc/systemd/system/display-manager.service" 2>/dev/null || true

# Enable NetworkManager
mkdir -p "$AIROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager.service" 2>/dev/null || true

# TTY1 autologin as fallback
mkdir -p "$AIROOTFS/etc/systemd/system/getty@tty1.service.d"
cat > "$AIROOTFS/etc/systemd/system/getty@tty1.service.d/autologin.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin liveuser --noclear %I 38400 linux
EOF

# Enable NetworkManager
mkdir -p "$AIROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager.service" 2>/dev/null || true

# Sudoers
mkdir -p "$AIROOTFS/etc/sudoers.d"
echo "root ALL=(ALL:ALL) NOPASSWD: ALL" > "$AIROOTFS/etc/sudoers.d/00-live"

# Desktop shortcut — put in skel so liveuser gets it on first login
mkdir -p "$AIROOTFS/etc/skel/Desktop" "$AIROOTFS/root/Desktop"
cat > "$AIROOTFS/etc/skel/Desktop/install-serikaos.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Install SerikaOS
Comment=Launch the SerikaOS installer
Exec=/usr/local/bin/serikaos-installer
Icon=system-software-install
Terminal=false
Categories=System;
StartupNotify=true
SingleMainWindow=true
EOF
chmod +x "$AIROOTFS/etc/skel/Desktop/install-serikaos.desktop"
cp "$AIROOTFS/etc/skel/Desktop/install-serikaos.desktop" "$AIROOTFS/root/Desktop/"
chmod +x "$AIROOTFS/root/Desktop/install-serikaos.desktop"

# Root bashrc
cat >> "$AIROOTFS/root/.bashrc" << 'EOF'
# SerikaOS live session
[[ -z "$SERIKAOS_WELCOMED" ]] && export SERIKAOS_WELCOMED=1 && fastfetch 2>/dev/null
EOF

# System-wide wallpaper setter for live Plasma
mkdir -p "$AIROOTFS/etc/xdg/autostart" "$AIROOTFS/usr/local/bin"
cat > "$AIROOTFS/usr/local/bin/serikaos-apply-wallpaper" << 'EOF'
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
chmod +x "$AIROOTFS/usr/local/bin/serikaos-apply-wallpaper"

cat > "$AIROOTFS/etc/xdg/autostart/serikaos-apply-wallpaper.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Apply SerikaOS Wallpaper
Exec=/usr/local/bin/serikaos-apply-wallpaper
OnlyShowIn=KDE;
X-KDE-AutostartPhase=1
NoDisplay=true
EOF

# --- 12. Custom GRUB config for ISO ---
echo "[*] Configuring ISO boot menu..."
cat > "$PROFILE_DIR/grub/grub.cfg" << GRUBCFG
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660
insmod all_video
insmod gfxterm
insmod gfxmenu
insmod png
insmod jpeg

set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm

# Load fonts from the GRUB prefix (which is /boot/grub on the ISO)
loadfont "\${prefix}/fonts/dejavu_11.pf2"
loadfont "\${prefix}/fonts/dejavu_12.pf2"
loadfont "\${prefix}/fonts/dejavu_14.pf2"
loadfont "\${prefix}/fonts/dejavu_16.pf2"
loadfont "\${prefix}/fonts/dejavu_24.pf2"
loadfont "\${prefix}/fonts/dejavu_bold_16.pf2"
loadfont "\${prefix}/fonts/dejavu_bold_24.pf2"

set theme="\${prefix}/themes/SerikaOS/theme.txt"
set timeout=3
set default=1

menuentry '  Try SerikaOS — Live Session' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} cow_spacesize=2G quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

menuentry '  Install SerikaOS' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} cow_spacesize=2G systemd.unit=graphical.target quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

submenu '  Advanced Options >' --class submenu {
    menuentry '  SerikaOS (Safe Graphics)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} nomodeset cow_spacesize=2G quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
        initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
    }
    menuentry '  SerikaOS (Copy to RAM)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} copytoram cow_spacesize=2G quiet splash plymouth.theme=serika loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
        initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
    }
    menuentry '  Boot from local disk' --class hd {
        exit
    }
}

menuentry '  Reboot' --class restart { reboot }
menuentry '  Shut Down' --class shutdown { halt }
GRUBCFG

# --- 13. Build ISO ---
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Building ISO with mkarchiso..."
echo "════════════════════════════════════════════════════════"
echo ""
mkarchiso -v -w "${SERIKA_WORK_DIR:-/tmp/archiso-work}" -o "${SERIKA_OUT_DIR:-/out}" "$PROFILE_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Build complete!"
echo "════════════════════════════════════════════════════════"
ls -lh /out/serikaos-*.iso 2>/dev/null || echo "WARNING: No ISO file found in output"
