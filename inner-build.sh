#!/bin/bash
# ============================================================
# SerikaOS — Inner Build Script (Containerized)
# ============================================================
set -euo pipefail

echo "════════════════════════════════════════════════════════"
echo "  SerikaOS — Building inside Arch Linux container"
echo "════════════════════════════════════════════════════════"

# --- 1. Dependencies ---
pacman -Sy --noconfirm archiso grub ttf-dejavu imagemagick base-devel git wget >/dev/null 2>&1

# --- 2. Build Calamares from AUR ---
echo "[*] Building Calamares from AUR..."
pacman-key --init
useradd -m builduser 2>/dev/null || true
echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser
sudo -u builduser bash -c '
    cd /home/builduser
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin && makepkg -si --noconfirm
    yay -S --noconfirm calamares ckbcomp qt5-xmlpatterns
'

# Create local repo
mkdir -p /serikaos-repo
find /home/builduser/.cache/yay -name "*.pkg.tar.zst" -exec cp {} /serikaos-repo/ \;
repo-add /serikaos-repo/serikaos-local.db.tar.gz /serikaos-repo/*.pkg.tar.zst
ln -sf serikaos-local.db.tar.gz /serikaos-repo/serikaos-local.db

# --- 3. Profile Setup ---
PROFILE_DIR="/tmp/serikaos-profile"
rm -rf "$PROFILE_DIR" && cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"
cp /serikaos/archiso-profile/pacman.conf "$PROFILE_DIR/pacman.conf"
cat >> "$PROFILE_DIR/pacman.conf" << EOF
[serikaos-local]
SigLevel = Optional TrustAll
Server = file:///serikaos-repo
EOF

cp /serikaos/archiso-profile/packages.x86_64 "$PROFILE_DIR/packages.x86_64"
AIROOTFS="$PROFILE_DIR/airootfs"
LOGO_SRC="/serikaos/built-in-media/logo/SerikaOS-LogoText.png"

# --- 4. THE CUSTOMIZATION (Live preparation of airootfs) ---
echo "[*] Injecting SerikaOS branding and configuration..."

# --- OVERWRITE ARCH BRANDING (Fixes 'Arch Logo still present') ---
mkdir -p "$AIROOTFS/usr/share/plymouth/themes/spinner"
mkdir -p "$AIROOTFS/usr/share/pixmaps"
cp "$LOGO_SRC" "$AIROOTFS/usr/share/plymouth/themes/spinner/watermark.png" 2>/dev/null || true
cp "$LOGO_SRC" "$AIROOTFS/usr/share/pixmaps/archlinux-logo.png" 2>/dev/null || true
cp "$LOGO_SRC" "$AIROOTFS/usr/share/pixmaps/serikaos-logo.png" 2>/dev/null || true

# --- Theme assets ---
mkdir -p "$AIROOTFS/usr/share/sddm/themes/SerikaOS"
cp -r /serikaos/sddm-theme/* "$AIROOTFS/usr/share/sddm/themes/SerikaOS/" 2>/dev/null || true
cp "$LOGO_SRC" "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Logo.png" 2>/dev/null || true

# Wallpaper
HERO_WALLPAPER="/serikaos/built-in-media/wallpapers/serika-pack-v1/wallpaper-3.jpg"
if [[ -f "$HERO_WALLPAPER" ]]; then
    cp "$HERO_WALLPAPER" "$AIROOTFS/usr/share/sddm/themes/SerikaOS/Background.jpg"
fi

# SDDM & Autologin
mkdir -p "$AIROOTFS/etc/sddm.conf.d"
cat > "$AIROOTFS/etc/sddm.conf.d/autologin.conf" << 'EOF'
[Autologin]
User=liveuser
Session=plasmax11.desktop
Relogin=false
[Theme]
Current=SerikaOS
EOF

# User setup via passwd/group (mkarchiso compatible)
mkdir -p "$AIROOTFS/etc/sudoers.d"
echo "liveuser ALL=(ALL:ALL) NOPASSWD: ALL" > "$AIROOTFS/etc/sudoers.d/00-live"
chmod 440 "$AIROOTFS/etc/sudoers.d/00-live"

# Setup dummy passwd if not exists to ensure liveuser exists
if ! grep -q "liveuser" "$AIROOTFS/etc/passwd" 2>/dev/null; then
    echo "liveuser:x:1000:1000:SerikaOS Live User:/home/liveuser:/bin/bash" >> "$AIROOTFS/etc/passwd"
    echo "liveuser:x:1000:" >> "$AIROOTFS/etc/group"
    echo "liveuser:!::0:99999:7:::" >> "$AIROOTFS/etc/shadow"
fi

# OS Identification
cat > "$AIROOTFS/etc/os-release" << 'EOF'
NAME="SerikaOS"
PRETTY_NAME="SerikaOS"
ID=serikaos
ID_LIKE=arch
LOGO=serikaos-logo
EOF

# Systemd Enablements
mkdir -p "$AIROOTFS/etc/systemd/system/display-manager.service.wants"
mkdir -p "$AIROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/sddm.service "$AIROOTFS/etc/systemd/system/display-manager.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/NetworkManager.service"

# --- 5. Bootloader Branding ---
echo "[*] Configuring GRUB & Syslinux..."
# GRUB Theme
THEME_GRUB="$PROFILE_DIR/grub/themes/SerikaOS"
mkdir -p "$THEME_GRUB"
cp -r /serikaos/grub-theme/* "$THEME_GRUB/"
if [[ -f "$HERO_WALLPAPER" ]]; then
    magick "$HERO_WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 "$THEME_GRUB/background.png"
fi

# --- 6. Build ISO ---
echo "[*] Executing mkarchiso..."
mkarchiso -v -w /tmp/archiso-work -o /out "$PROFILE_DIR"

echo "════════════════════════════════════════════════════════"
echo "  GOATED BUILD COMPLETE"
echo "════════════════════════════════════════════════════════"
