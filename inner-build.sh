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
echo "[*] Building Calamares from AUR..."
pacman-key --init
pacman -S --noconfirm --needed base-devel git >/dev/null 2>&1

# Create a non-root build user
useradd -m builduser 2>/dev/null || true
echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser

# Install yay
sudo -u builduser bash -c '
    cd /home/builduser
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
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
repo-add /serikaos-repo/serikaos-local.db.tar.gz /serikaos-repo/*.pkg.tar.zst
ln -sf serikaos-local.db.tar.gz /serikaos-repo/serikaos-local.db
ln -sf serikaos-local.files.tar.gz /serikaos-repo/serikaos-local.files

# --- 3. Copy releng base profile ---
PROFILE_DIR="/tmp/serikaos-profile"
rm -rf "$PROFILE_DIR"
cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"

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

# --- 9. Wallpapers & media ---
echo "[*] Packaging SerikaOS media assets..."
mkdir -p "$AIROOTFS/usr/share/serikaos"
cp -r /serikaos/built-in-media/* "$AIROOTFS/usr/share/serikaos/" 2>/dev/null || true
cp "$AIROOTFS/usr/share/serikaos/logo/SerikaOS-LogoText.png" "$AIROOTFS/usr/share/serikaos/logo.png" 2>/dev/null || true
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

# Boot logo asset (used by Plymouth customization in chroot)
if command -v magick &>/dev/null; then
    magick -size 900x220 xc:none \
        -font DejaVu-Sans-Bold -pointsize 120 -fill white -gravity center -annotate -130+0 "Serika" \
        -font DejaVu-Sans-Bold -pointsize 120 -fill "#e8a0bf" -gravity center -annotate +260+0 "OS" \
        "$AIROOTFS/usr/share/serikaos/boot-logo.png" 2>/dev/null || true
fi

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
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-install
TEXT HELP
Boot the SerikaOS installer environment on BIOS.
Use this to launch the graphical install flow.
ENDTEXT
MENU LABEL Install SerikaOS (x86_64, BIOS)
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} systemd.unit=graphical.target quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0

LABEL serika-safe
TEXT HELP
Boot SerikaOS with safe graphics mode.
ENDTEXT
MENU LABEL SerikaOS safe graphics mode
LINUX /arch/boot/x86_64/vmlinuz-linux
INITRD /arch/boot/x86_64/initramfs-linux.img
APPEND archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} nomodeset quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
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

LOGO_SRC="/serikaos/built-in-media/logo/SerikaOS-LogoText.png"
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



# Deterministic live-user setup at build time (inside chroot)
mkdir -p "$AIROOTFS/root"
cat > "$AIROOTFS/root/customize_airootfs.sh" << 'EOF'
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

# --- APPLY STAGED CUSTOMIZATIONS (Overwriting defaults) ---
if [ -d /opt/serikaos-custom ]; then
    cp -rv /opt/serikaos-custom/* /
    rm -rf /opt/serikaos-custom
fi

# Ensure executable permissions
chmod +x /usr/local/bin/serikaos-installer /usr/local/bin/serikaos-welcome 2>/dev/null || true

mkdir -p /home/liveuser/Desktop
cp -a /etc/skel/. /home/liveuser/ 2>/dev/null || true
chown -R liveuser:liveuser /home/liveuser

# Polkit rule to allow liveuser to run everything without password
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/49-nopasswd-calamares.rules << 'POLKITEOF'
polkit.addRule(function(action, subject) {
    if (subject.user == "liveuser") {
        return polkit.Result.YES;
    }
});
POLKITEOF

# --- SDDM autologin into Plasma (proper full session management) ---
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << 'SDDMEOF'
[Autologin]
User=liveuser
Session=plasmax11.desktop
Relogin=false

[Theme]
Current=SerikaOS

[Users]
MinimumUid=1000
MaximumUid=65000
RememberLastUser=false
RememberLastSession=false
SDDMEOF

# Enable SDDM as display manager
systemctl enable sddm.service 2>/dev/null || \
    ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service 2>/dev/null || true

# Ensure graphical target is default
systemctl set-default graphical.target 2>/dev/null || \
    ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target 2>/dev/null || true

# Environment variables for display scaling
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
# Performance tweaks for VMs
KWIN_X11_NO_SYNC_TO_VBLANK=1
KWIN_LOWLATENCY=1
KWIN_EFFECTS_FOR_LOW_PERFORMANCE=1
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

# Apply custom OS branding (overwriting files installed by packages)
cat > /etc/os-release << 'OSREOF'
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
LOGO=serikaos-logo
OSREOF

cat > /etc/lsb-release << 'LSBREOF'
DISTRIB_ID=SerikaOS
DISTRIB_RELEASE=rolling
DISTRIB_DESCRIPTION="SerikaOS Rolling platform"
DISTRIB_CODENAME=serika
LSBREOF

chmod 644 /etc/os-release /etc/lsb-release

# Force SerikaOS logo for Plymouth (boot splash)
# Force SerikaOS logo for Plymouth (boot splash)
mkdir -p /usr/share/plymouth/themes/spinner
cp /usr/share/serikaos/logo/SerikaOS-LogoText.png /usr/share/plymouth/themes/spinner/watermark.png 2>/dev/null || true
cp /usr/share/serikaos/logo/SerikaOS-LogoText.png /usr/share/pixmaps/archlinux-logo.png 2>/dev/null || true
cp /usr/share/serikaos/logo/SerikaOS-LogoText.png /usr/share/pixmaps/serikaos-logo.png 2>/dev/null || true

# Copy installer desktop shortcut to liveuser Desktop
cp /usr/share/applications/serikaos-installer.desktop /home/liveuser/Desktop/ 2>/dev/null || true
chmod +x /home/liveuser/Desktop/*.desktop 2>/dev/null || true
chown -R liveuser:liveuser /home/liveuser/Desktop

# Trust desktop files so KDE doesn't show "untrusted" warnings
mkdir -p /home/liveuser/.local/share
cat > /home/liveuser/.local/share/trusted-desktop-files << 'TRUSTEOF'
/home/liveuser/Desktop/install-serikaos.desktop
/home/liveuser/Desktop/serikaos-installer.desktop
TRUSTEOF
chown -R liveuser:liveuser /home/liveuser/.local

EOF
chmod +x "$AIROOTFS/root/customize_airootfs.sh"

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
loadfont "\${prefix}/fonts/dejavu_14.pf2"
loadfont "\${prefix}/fonts/dejavu_bold_16.pf2"

set theme="\${prefix}/themes/SerikaOS/theme.txt"
set timeout=3
set default=1

menuentry '  Try SerikaOS — Live Session' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

menuentry '  Install SerikaOS' --class serikaos --class linux {
    set gfxpayload=keep
    linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} cow_spacesize=2G systemd.unit=graphical.target quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
    initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
}

submenu '  Advanced Options >' --class submenu {
    menuentry '  SerikaOS (Safe Graphics)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} nomodeset cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
        initrd (\${root})/arch/boot/x86_64/initramfs-linux.img
    }
    menuentry '  SerikaOS (Copy to RAM)' --class serikaos {
        linux (\${root})/arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=${ISO_LABEL:-SERIKAOS} copytoram cow_spacesize=2G quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0
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
mkarchiso -v -w /tmp/archiso-work -o /out "$PROFILE_DIR"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Build complete!"
echo "════════════════════════════════════════════════════════"
ls -lh /out/serikaos-*.iso 2>/dev/null || echo "WARNING: No ISO file found in output"
