# Arch Linux Dual-Display Boot Configuration

> **Purpose**: Configure Arch Linux to automatically use the appropriate display - either a full 4K external monitor when connected or the internal laptop display when undocked.

## System Information

- **Hardware**: AMD GPU with KMS (`amdgpu` module)
- **Displays**:
  - Internal: `eDP-1` (laptop screen)
  - External: `DP-1` (HDMI via DisplayPort bridge)
- **Boot loader**: systemd-boot

## Solution Overview

This setup creates two separate boot entries in systemd-boot:
1. `arch-external.conf` - Optimized for 4K external monitor
2. `arch-internal.conf` - Configured for internal laptop display

## Installation

### Automatic Setup (Recommended)

The included `setup-boot-entries.sh` script automates the creation of boot entries:

```bash
# Make the script executable
chmod +x setup-boot-entries.sh

# Run the script with sudo
sudo ./setup-boot-entries.sh
```

The script will:
1. Find your most recent kernel configuration
2. Create two boot entries (external and internal)
3. Update your loader.conf to default to the internal display

### Manual Setup

If you prefer to set up manually, follow these steps:

#### 1. Identify Display Outputs

First, determine the correct display identifiers:

```bash
find /sys/class/drm/card1-*/status | xargs -I{} sh -c 'echo {}; cat {}'
```

#### 2. Finding the Correct DisplayPort Output for HDMI

Modern laptops often route HDMI through a **DisplayPort bridge**, so the HDMI port appears as `DP-x` (like `DP-1`, `DP-2`, etc.) in `/sys/class/drm`. The exact mapping depends on your laptop model and firmware.

To identify your external monitor port:

1. **Try each DP port systematically**:
   ```bash
   sudo vim /boot/loader/entries/2025-04-19_11-14-30_linux.conf
   ```
   Add this to the options line, starting with DP-1:
   ```
   video=DP-1:e
   ```

2. **Reboot and check connection status**:
   ```bash
   reboot
   ```
   After reboot, run:
   ```bash
   find /sys/class/drm/card1-*/status | xargs -I{} sh -c 'echo {}; cat {}'
   ```
   Look for output showing:
   ```
   /sys/class/drm/card1-DP-1/status
   connected
   ```
   If you see "connected", you've found your HDMI port.
   
   If it shows "disconnected", repeat with `DP-2:e`, `DP-3:e`, etc.

3. **Once identified, use in your configuration**:
   ```
   video=eDP-1:d video=DP-1:3840x2160@60
   ```
   This disables the internal screen and sets the external monitor to 4K resolution.

#### 3. Create Boot Entries

Create two configuration files in `/boot/loader/entries/`:

##### External Display Configuration (4K TTY)
```
# /boot/loader/entries/arch-external.conf
title   Arch Linux (external)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=... rw rootfstype=ext4 video=eDP-1:d video=DP-1:3840x2160@60
```

##### Internal Display Configuration
```
# /boot/loader/entries/arch-internal.conf
title   Arch Linux (internal)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=... rw rootfstype=ext4 video=DP-1:d
```

#### 4. Configure Default Boot Option

Edit `/boot/loader/loader.conf`:

```
default arch-internal.conf
timeout 4
```

## Recovery Instructions

If the system boots with the wrong configuration (e.g., external monitor selected but not connected):

1. **Immediate solution**: Reboot and select "Arch Linux (internal)" from the boot menu
2. **Manual fix**: Restore the default configuration:
   ```bash
   sudo cp /boot/loader/entries/arch-internal.conf /boot/loader/entries/arch.conf
   ```
3. **Create a recovery script** (optional):
   
   Create a file at `/usr/local/bin/fix-display-boot.sh`:
   ```bash
   #!/bin/bash
   set -euo pipefail
   
   # Reset to internal display configuration
   cp /boot/loader/entries/arch-internal.conf /boot/loader/entries/arch.conf
   echo "Display boot configuration reset to internal display."
   ```
   
   Make it executable:
   ```bash
   sudo chmod +x /usr/local/bin/fix-display-boot.sh
   ```

## Kernel Parameter Details

- `video=eDP-1:d` - Disables the internal display
- `video=DP-1:3840x2160@60` - Sets external display to 4K resolution at 60Hz
- `video=DP-1:d` - Disables the external display

## Troubleshooting

If you encounter issues:

1. **Check your display identifiers**: Your system might use different identifiers than `eDP-1` and `DP-1`. Run the following command to check:
   ```bash
   find /sys/class/drm/card*-*/status | xargs -I{} sh -c 'echo {}; cat {}'
   ```

2. **Verify resolution support**: Not all displays support 3840x2160@60. Use a resolution supported by your monitor.

3. **Boot parameters not working**: Try adding `nomodeset` to test if it's a KMS issue, or try using `fbcon=map:0` to ensure the console is mapped correctly.
