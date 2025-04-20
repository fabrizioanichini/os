# Arch Linux Setup Guide

## Quick Navigation

- [Essential Packages](#essential-packages)
- [Wi-Fi Connection](#wi-fi-connection)
- [Additional Resources](#additional-resources)
  - [Dual Boot Display Configuration](./arch/tty/dual-display-boot.md)

## Essential Packages

This section helps you set up basic terminal tools and network connectivity on your Arch Linux installation.

### What You'll Install

- **vim** - Powerful terminal text editor
- **tmux** - Terminal multiplexer for managing multiple terminal sessions
- **man-db** - Documentation system for viewing manual pages
- **iwd** - Modern wireless daemon for Wi-Fi connectivity

### Installation Steps

1. Make the installation script executable:

```bash
chmod +x install-essential.sh
```

2. Run the installation script:

```bash
./install-essential.sh
```

The script automatically:
- Installs all essential packages
- Enables the iwd service for Wi-Fi connectivity
- Starts the iwd service so you can connect immediately

## Wi-Fi Connection

After running the installation script, you can connect to Wi-Fi networks using the `iwctl` command-line tool:

```bash
iwctl
```

### Basic iwctl Commands

Once in the iwctl interactive prompt:

1. List wireless devices:
   ```
   device list
   ```

2. Scan for networks:
   ```
   station wlan0 scan
   ```

3. List available networks:
   ```
   station wlan0 get-networks
   ```

4. Connect to a network:
   ```
   station wlan0 connect NETWORK_NAME
   ```
   (Replace `wlan0` with your device name if different)

## Additional Resources

- [Arch Wiki: iwd (Intelligent Wireless Daemon)](https://wiki.archlinux.org/title/Iwd)
- [Dual Boot Display Configuration](./tty/dual-display-boot.md)
