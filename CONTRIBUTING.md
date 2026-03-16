# SerikaOS — Development & PR Guide

Welcome to the **SerikaOS** core build system. This repository contains the source code, build scripts, and configuration profiles for generating our pure Arch-based live ISO.

## 📜 Serika FOSS License (SFL)

SerikaOS is released under the **Serika FOSS License**.

1.  **Freedom of Use**: You are free to use, study, and modify this software for any personal or commercial purpose.
2.  **Attribution (Required)**: Any redistribution of this software, or derivatives thereof, must include clear and visible attribution to the original **SerikaOS** project and its contributors.
3.  **No Warranty**: This software is provided "as is", without warranty of any kind.

---

## 🚀 Pull Request (PR) Requirements

To maintain the "Goated" status of SerikaOS, all contributions must adhere to these standards:

### 1. Style & Aesthetics
- All UI changes (SDDM, Plasma, GRUB) must follow the **Serika Kuromi** aesthetic (Frosted glass, HSL-based pink/teal/navy palettes).
- No generic browser defaults. Use modern typography (DejaVu/Inter).

### 2. Technical Integrity
- **Pure Arch Only**: Never include third-party repositories (Endeavour, Manjaro, etc.) in the core build scripts.
- **Reproducibility**: Changes to `inner-build.sh` must be tested within the Docker container.
- **Performance**: Squashing and compression must be balanced (Level 3 for development, higher for production).

### 3. Submission Format
- **Description**: Each PR must explain *why* the change is being made and include a screenshot if it affects the UI.
- **Atomic Commits**: Keep your commits clean and descriptive.

---

## 🛠️ Build Workflow

1.  **Clone**: `git clone https://github.com/SerikaOS/SerikaOS-Arch.git`
2.  **Modify**: Apply your changes to `archiso-profile` or `inner-build.sh`.
3.  **Build**: `sudo ./build-docker-iso.sh` (Requires Docker).
4.  **Test**: Boot the generated ISO in a VM (VirtualBox/QEMU) ensuring X11 session stability.

---
*SerikaOS — Your system. Your rules.*
