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

## Implementation Options

You can set up the dual-display configuration using either the **automated script** or by following the **manual steps**.

### Option 1: Automated Script (Recommended)

For a quick and easy setup, use the included `dual-display-setup.sh` script:

1. **Make the script executable**:
   ```bash
   chmod +x dual-display-setup.sh
   ```

2. **Run the script with sudo**:
   ```bash
   sudo ./dual-display-setup.sh
   ```

The script will:
- Automatically detect your displays
- Create the necessary boot entries
- Set up the boot loader configuration
- Create a recovery script

#### Advanced Script Usage

The script supports several command-line options:

```bash
sudo ./dual-display-setup.sh [options]
```

Options:
- `-h, --help`: Show help message
- `-r, --root-uuid UUID`: Specify root partition UUID manually
- `-i, --internal DEVICE`: Specify internal display (default: eDP-1)
- `-e, --external DEVICE`: Specify external display (default: auto-detect)
- `-d, --detect-only`: Only detect displays without making changes
- `-y, --yes`: Non-interactive mode (answer yes to all prompts)

Examples:
```bash
# Just detect available displays
sudo ./dual-display-setup.sh --detect-only

# Specify everything manually
sudo ./dual-display-setup.sh --root-uuid 12345678-abcd-1234-5678-abcdef123456 --internal eDP-1 --external DP-1
```

### Option 2: Manual Configuration

If you prefer to set everything up manually or need more control, follow these steps:

## Manual Implementation Steps

### 1. Identify Display Outputs

First, determine the correct display identifiers:

```bash
find /sys/class/drm/card1-*/status | xargs -I{} sh -c 'echo {}; cat {}'
```

### 2. Finding the Correct DisplayPort Output for HDMI

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

### 3. Create Boot Entries

Create two configuration files in `/boot/loader/entries/`:

#### External Display Configuration (4K TTY)
```
# /boot/loader/entries/arch-external.conf
title   Arch Linux (external)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=... rw rootfstype=ext4 video=eDP-1:d video=DP-1:3840x2160@60
```

#### Internal Display Configuration
```
# /boot/loader/entries/arch-internal.conf
title   Arch Linux (internal)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=... rw rootfstype=ext4 video=DP-1:d
```

### 4. Configure Default Boot Option

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
   cp /boot/loader/entries/arch-internal.conf /boot/loader/entries/arch.conf
   ```
3. **Using the recovery script** (if you used the automated setup):
   ```bash
   sudo /usr/local/bin/fix-display-boot.sh
   ```

## Kernel Parameter Details

- `video=eDP-1:d` - Disables the internal display
- `video=DP-1:3840x2160@60` - Sets external display to 4K resolution at 60Hz
- `video=DP-1:d` - Disables the external display

---

*Note: Replace the `PARTUUID` value in the configuration files with your system's actual root partition UUID.*