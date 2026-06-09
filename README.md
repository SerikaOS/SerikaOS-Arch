<p align="center">
  <h1 align="center">SerikaOS</h1>
  <p align="center">
    <em>A premium rolling Linux distribution themed around Serika Kuromi from Blue Archive</em>
  </p>
  <p align="center">
    <strong>Your system. Your rules. Zero bloatware.</strong>
  </p>
</p>

---

## Philosophy

SerikaOS is built on three pillars:

1. **User Freedom** — You own every decision. From your desktop environment to your audio stack, bootloader, package manager, and browser — nothing is forced, nothing is assumed. During installation, you pick exactly what you want. Zero bloatware.

2. **Privacy First** — DNS-over-HTTPS, MAC randomization, kernel hardening, telemetry blocking, AppArmor, and Firejail sandboxing. Your data stays yours.

3. **Rolling Power** — Fresh packages, fast tooling, and full user control with a beautiful, user-friendly installer.

## Features

| Feature | Details |
|---|---|
| **Base** | SerikaOS rolling platform |
| **Installer** | Calamares GUI with full Serika branding |
| **Desktop Choices** | KDE Plasma, GNOME, Hyprland, Budgie, Sway, i3, XFCE, Cinnamon, or CLI-only |
| **Bootloader Choices** | GRUB (with Serika theme), systemd-boot, rEFInd |
| **Audio Choices** | PipeWire, PulseAudio, or none |
| **Display Manager** | SDDM (with Serika theme), GDM, LightDM, Ly, or TTY |
| **Package Manager** | pacman, Discover, or GNOME Software |
| **Kernel Options** | linux, linux-zen, linux-hardened, linux-lts |
| **Privacy** | Firewall, DoH DNS, MAC randomization, AppArmor, Firejail |
| **Theme** | Serika Kuromi — dark navy, pink accents, teal highlights |

## Screenshots

The GRUB bootloader, Calamares installer, SDDM login screen, and desktop are all themed with the Serika Kuromi color palette.

## Building

### Prerequisites

- Linux host system with `archiso` available
- `archiso` package installed
- Root privileges
- ~10GB free disk space

### Build the ISO

```bash
# Install archiso
sudo pacman -S archiso

# Clone this repository
git clone https://github.com/serikaos/SerikaOS-Arch.git
cd SerikaOS-Arch

# Build the ISO
sudo bash build.sh
```

The ISO will be output to `out/serikaos-<date>-x86_64.iso`.

### Build Commands

| Command | Description |
|---|---|
| `sudo bash build.sh` | Build the full ISO |
| `sudo bash build.sh clean` | Remove build artifacts |
| `sudo bash build.sh prepare` | Prepare profile without building |

### Testing in a VM

```bash
# QEMU (recommended)
qemu-system-x86_64 -boot d -cdrom out/serikaos-*.iso -m 4G -enable-kvm

# VirtualBox — create a new VM and attach the ISO
```

### Writing to USB

```bash
sudo dd bs=4M if=out/serikaos-*.iso of=/dev/sdX status=progress oflag=sync
```

> ⚠️ Replace `/dev/sdX` with your actual USB device. Use `lsblk` to identify it.

## Project Structure

```
SerikaOS-Arch/
├── archiso-profile/          # Archiso profile
│   ├── profiledef.sh         # ISO metadata and build config
│   ├── packages.x86_64       # Package list for live ISO
│   ├── pacman.conf            # Pacman configuration
│   └── airootfs/              # Root filesystem overlay
│       ├── etc/
│       │   ├── calamares/     # Calamares installer configs
│       │   │   ├── settings.conf
│       │   │   ├── branding/serikaos/
│       │   │   │   ├── branding.desc
│       │   │   │   ├── stylesheet.qss
│       │   │   │   └── show.qml
│       │   │   └── modules/
│       │   │       ├── netinstall.conf  ← User choice engine
│       │   │       ├── shellprocess.conf ← Privacy hardening
│       │   │       └── ... (other modules)
│       │   └── skel/          # Default user home skeleton
│       │       └── .config/
│       │           ├── hypr/hyprland.conf
│       │           ├── waybar/
│       │           ├── kdeglobals
│       │           └── kwinrc
│       └── usr/share/
│           ├── grub/themes/SerikaOS/
│           ├── sddm/themes/SerikaOS/
│           ├── wallpapers/SerikaOS/
│           └── sounds/SerikaOS/
├── grub-theme/                # GRUB bootloader theme
│   ├── theme.txt
│   ├── background.png
│   ├── icons/
│   └── install.sh
├── sddm-theme/               # SDDM login theme
│   ├── Main.qml
│   ├── theme.conf
│   └── metadata.desktop
├── built-in-media/            # Media assets
│   ├── audio/
│   └── wallpapers/
├── build.sh                   # Main build script
└── README.md
```

## Customization

### Adding packages to the installer

Edit `archiso-profile/airootfs/etc/calamares/modules/netinstall.conf` to add or remove package choices.

### Changing the color scheme

The Serika palette is used throughout:

| Color | Hex | Usage |
|---|---|---|
| Dark Navy | `#1a1b2e` | Backgrounds |
| Deep Navy | `#12131f` | Input fields, sidebars |
| Soft Pink | `#e8a0bf` | Primary accent, selections |
| Teal | `#5cc6d0` | Secondary accent, links |
| Warm Gold | `#d4a853` | Tertiary accent, warnings |
| Light Gray | `#c8c8d8` | Body text |
| Dim Gray | `#6a6a8a` | Muted text |

### Adding wallpapers

Drop images into `built-in-media/wallpapers/serika-pack-v1/` — they'll be copied to the installed system during build.

## Privacy & Security

SerikaOS applies these hardening measures via post-install scripts (user can toggle during installation):

- **UFW Firewall** — deny incoming by default
- **DNS-over-HTTPS** — Quad9 + Cloudflare Security via systemd-resolved
- **MAC Randomization** — NetworkManager spoofs MAC addresses
- **Kernel Hardening** — sysctl tweaks (ASLR, dmesg restrict, ptrace scope, SYN cookies)
- **Telemetry Blocking** — `/etc/hosts` blocklist for known telemetry endpoints
- **AppArmor** — mandatory access control for apps
- **Firejail** — sandbox profiles for browsers and internet-facing apps

## Credits

- **Serika Kuromi** character from [Blue Archive](https://bluearchive.nexon.com/)
- Built on [Arch Linux](https://archlinux.org/) with [archiso](https://gitlab.archlinux.org/archlinux/archiso)
- Installer powered by [Calamares](https://calamares.io/)
- Inspired by [CachyOS](https://cachyos.org/) and the Arch Linux community

## License

This project is licensed under the GPL-3.0 License.
