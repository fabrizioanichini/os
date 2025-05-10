#!/bin/bash

set -e

KEYMAP_NAME="swap-ctrl-caps"
MAP_DIR="/usr/share/kbd/keymaps/custom"
MAP_FILE="${MAP_DIR}/${KEYMAP_NAME}.map"

echo "Creating custom keymap directory..."
sudo mkdir -p "$MAP_DIR"

# Start from the default keymap, dump it, then modify just the necessary lines
echo "Dumping current keymap and creating custom version..."
sudo dumpkeys | \
  sed \
    -e 's/^keycode 29 = .*/keycode 29 = Caps_Lock/' \
    -e 's/^keycode 58 = .*/keycode 58 = Control/' \
  | sudo tee "$MAP_FILE" > /dev/null

# Load it immediately
echo "Loading custom keymap..."
sudo loadkeys "$MAP_FILE"

# Persist in vconsole.conf
echo "Setting up /etc/vconsole.conf..."
sudo sed -i '/^KEYMAP=/d' /etc/vconsole.conf 2>/dev/null || true
echo "KEYMAP=custom/${KEYMAP_NAME}" | sudo tee -a /etc/vconsole.conf > /dev/null

# Optional mkinitcpio step
echo "If you want this to apply in early boot (initramfs), run:"
echo "  sudo mkinitcpio -P"

echo "Done. Caps Lock <-> Control key swap applied and persisted."
