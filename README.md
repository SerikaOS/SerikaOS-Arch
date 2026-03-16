# SerikaOS — Pure Arch Build System

![SerikaOS Logo](built-in-media/logo/serikaos-logo.png)

SerikaOS is a premium, Rolling-release Linux distribution based on **Pure Arch Linux**. This repository contains the containerized build system used to generate the SerikaOS Live ISO.

## ✨ Features
- **Pure Arch Linux**: Zero third-party repositories. Every package is pulled from official Arch repos or built from the AUR.
- **KDE Plasma 6**: A curated, high-performance desktop environment with X11 session stability for VMs.
- **Custom SDDM Theme**: "SerikaOS" premium frosted-glass login interface.
- **Plymouth Boot Splash**: Seamless transition from bootloader to desktop.
- **Calamares Installer**: Fully customized GUI installer with SerikaOS branding.

## 🛠️ Quick Start

### Prerequisites
- Linux Host (Arch, Ubuntu, Fedora, etc.)
- Docker installed and running
- At least 20GB of free disk space

### Build the ISO
```bash
# Clone the repository
git clone https://github.com/SerikaOS/SerikaOS-Arch.git
cd SerikaOS-Arch

# Run the build script (takes ~15-30 mins depending on AUR compilation)
sudo ./build-docker-iso.sh
```

The resulting ISO will be in the `out/` directory.

## 🤝 Contributing
Please read our [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## ⚖️ License
This project is licensed under the **Serika FOSS License** - see the [LICENSE](LICENSE) file for details.

---
*SerikaOS — Your system. Your rules.*
