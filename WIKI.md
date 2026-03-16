# 📘 SerikaOS Comprehensive Build Guide

This document provides extreme detail on how the **SerikaOS** build system works, how to customize it, and how to generate your own rolling-release ISOs.

## 🏗️ Architecture Overview

SerikaOS uses a **Containerized Build System**. This means you don't need to install anything on your host machine except for **Docker**.

1.  **Host Script (`build-docker-iso.sh`)**: This is the orchestrator. It starts an Arch Linux container and mounts the local `SerikaOS-Arch` folder to `/serikaos`.
2.  **Container Environment**: Inside the container (managed by the `archlinux:latest` image), it has the full Arch Linux toolset without polluting your host.
3.  **Inner Script (`inner-build.sh`)**: This script runs *inside* the container. It:
    *   Builds **Calamares** (the installer) and its dependencies from source (the AUR).
    *   Creates a **Local Repository** (`/serikaos-repo`) containing those built packages.
    *   Customizes the **Archiso Profile** (releng base).
    *   Injects **Branding** (Logos, Plymouth, Wallpapers, SDDM Themes).
    *   Executes `mkarchiso` to wrap everything into the final `.iso`.

## 🛠️ How to Build

### 1. Prerequisites
Ensure Docker is installed and your user is in the `docker` group.
```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### 2. Execution
Run the orchestrator script:
```bash
bash build-docker-iso.sh
```
*Wait approximately 45-60 minutes.* The first build takes longer because it compiles Calamares from source. Subsequent builds use Docker layer caching where possible.

### 3. Output
The final ISO will be placed in the `out/` directory:
- `out/serikaos-YYYY.MM.DD-x86_64.iso`

## 🎨 Branding Customization

### Wallpapers
Place your wallpapers in `built-in-media/wallpapers/`. The build script automatically picks up files in `serika-pack-v1/` and sets `wallpaper-3.jpg` as the system default.

### Logos
- **Main Text Logo**: `built-in-media/logo/SerikaOS-LogoText.png`
- **Icon Logo**: `built-in-media/logo/serikaos-logo.png`
These are automatically resized for Plymouth, Calamares, and the SDDM theme.

### SDDM (Login Screen)
The theme logic is located in `sddm-theme/`. It uses **QtQuick** and **QML**.
- `Main.qml`: The core layout (Astronaut sidebar style).
- `Logo.png`: The sidebar branding (automatically copied during build).

## 🧩 Advanced Configuration

### Modifying Package Lists
To add or remove software from the Live ISO, edit `archiso-profile/packages.x86_64`. Make sure to avoid bloating the ISO—SerikaOS follows the Arch philosophy of installing only the essentials for the live session.

### The `airootfs` (Root Filesystem)
Static configuration files (like `/etc/hosts` or system default settings) are located in `archiso-profile/airootfs/`. These are overlayed onto the ISO root.

### Dynamic Customization
The `inner-build.sh` script generates a `customize_airootfs.sh` script at build time. This script runs inside the ISO's chroot environment and handles:
- User creation (`liveuser`).
- Plymouth theme initialization.
- SDDM autologin.
- OS identification (`/etc/os-release`).

## 🚢 Release Process

1.  Verify the ISO in a virtual machine (QEMU or VirtualBox).
2.  Commit your changes to the repo.
3.  Tag the release (e.g., `v0.0.1`).
4.  Upload the `.iso` and its `.sha256` to the GitHub Release page.

---
*SerikaOS — Your System. Your Rules.*
