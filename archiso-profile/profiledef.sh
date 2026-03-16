#!/usr/bin/env bash
# ============================================================
# SerikaOS — Archiso Profile Definition
# Defines how the ISO is built — keep this minimal and correct
# ============================================================
# shellcheck disable=SC2034

iso_name="serikaos"
iso_label="SERIKAOS_$(date +%Y%m)"
iso_publisher="SerikaOS <https://github.com/serikaos>"
iso_application="SerikaOS Live/Install Medium"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'bios.syslinux.mbr'
    'bios.syslinux.eltorito'
    'uefi-ia32.grub.esp'
    'uefi-x64.grub.esp'
    'uefi-ia32.grub.eltorito'
    'uefi-x64.grub.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')

# File permissions
file_permissions=(
    ["/etc/shadow"]="0:0:400"
    ["/root"]="0:0:750"
)
