# Arch Linux Setup Guide

## Quick Navigation

- [Introduction](#introduction)
- [Framework Laptop Installation](#framework-laptop-installation)
- [Essential Packages](#essential-packages)
- [Wi-Fi Connection](#wi-fi-connection)
- [Additional Resources](#additional-resources)
  - [Dual Boot Display Configuration](./tty/dual-display-boot.md)

## Introduction

This guide documents the process of setting up a complete Arch Linux environment starting from a minimal installation. It aims to restore a fully functional system with all necessary tools and configurations.

## Framework Laptop Installation

This section details the Arch Linux installation process on a Framework laptop.

### Hardware Preparation

Before installation, the storage was completely wiped to ensure a clean start:

```bash
sudo dd if=/dev/zero of=/dev/nvme0n1 bs=1M status=progress
```

### Installation Method

The installation used `archinstall` with the following configuration:

- **Filesystem**: ext4 partition layout
- **Additional Packages**: linux-firmware (required for Framework hardware)
- **Audio System**: PipeWire
- **Profile**: Minimal Setup

### Framework-Specific Considerations

Framework laptops (particularly AMD Ryzen 7040 series) have specific hardware requirements that need attention during installation:

- Firmware packages are essential for proper hardware support
- Follow the official [Arch Wiki page for Framework Laptop 13](https://wiki.archlinux.org/title/Framework_Laptop_13_(AMD_Ryzen_7040_Series)) for detailed hardware compatibility information
- Network configuration from the installation ISO was preserved to ensure connectivity after first boot

### Post-Installation

After the base installation, the system was ready for the essential packages setup described in the next section.


## Additional Resources

- [Arch Wiki: iwd (Intelligent Wireless Daemon)](https://wiki.archlinux.org/title/Iwd)
- [Arch Wiki: Framework Laptop 13](https://wiki.archlinux.org/title/Framework_Laptop_13_(AMD_Ryzen_7040_Series))
- [Dual Boot Display Configuration](./tty/dual-display-boot.md)
