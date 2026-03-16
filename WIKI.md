# SerikaOS — Technical Documentation

Welcome to the internal engineering wiki for **SerikaOS**. This document provides an exhaustive breakdown of the architectural decisions, build pipeline, and system configurations.

## 🏗️ The Build Architecture

SerikaOS uses a **Containerized Layered Build (CLB)** strategy. This ensures that the ISO environment is identical regardless of whether you are building on Arch, Ubuntu, or even macOS.

### 1. The Orchestrator: `build-docker-iso.sh`
- **Role**: Host-side wrapper.
- **Function**: Pulls a fresh `archlinux:latest` Docker image, mounts the local source directory as a read-only volume, and executes the inner build logic with elevated privileges.
- **Network**: Uses `--network host` to bypass Docker’s virtual NAT, preventing DNS timeouts.

### 2. The Engine: `inner-build.sh`
This script runs *inside* the container and performs the heavy lifting:
- **Dependency Bootstrap**: Installs `archiso`, `grub`, `git`, and build tools.
- **AUR Compilation**: Since SerikaOS is "Pure Arch," we do not use pre-built binaries from third parties. We compile `calamares` and its dependencies directly from the AUR to ensure binary integrity.
- **Local Repository Creation**: Built packages are indexed into a local Pacman repository located at `/serikaos-repo`.
- **Profile Customization**: Patches the standard Arch `releng` profile with SerikaOS branding.

---

## 🎨 Design Systems

### GRUB2 Bootloader
- **Path**: `grub-theme/`
- **Logic**: Fonts are dynamically generated into `.pf2` format during build. We use `${prefix}` pathing in `grub.cfg` to ensure icons load correctly across different hardware.

### SDDM Login
- **Path**: `sddm-theme/`
- **Stack**: Qt 6 + QML + Qt5Compat.
- **Environment**: Performance flags like `KWIN_EFFECTS_FOR_LOW_PERFORMANCE=1` are injected via `/etc/environment` to ensure smoothness in VirtualBox.

---

## 🛠️ Step-by-Step: Modification to Build

If you want to add a new package or change a system file:

1.  **Add Package**: Edit `archiso-profile/packages-live.x86_64`.
2.  **Add/Modify File**: Place it in `archiso-profile/airootfs/...` following the standard Linux filesystem hierarchy.
3.  **Update Logic**: If it requires a service to be enabled, add the `systemctl enable` symlink in `inner-build.sh`.
4.  **Execute**: Run `sudo ./build-docker-iso.sh`.

---

## ⚡ Performance Tuning
We use SquashFS with `zstd` compression.
- **Development**: Compression level **3** (Fast builds, larger ISO).
- **Production**: Compression level **15** (Slower builds, smallest ISO).

---
*Document Version: 1.0.0*
