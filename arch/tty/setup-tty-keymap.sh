#!/bin/bash

set -e

# Name of the custom keymap
KEYMAP_NAME="swap-ctrl-caps"
MAP_DIR="/usr/share/kbd/keymaps/custom"
MAP_FILE="${MAP_DIR}/${KEYMAP_NAME}.map"

# Create the custom keymap directory if it doesn't exist
echo "Creating custom keymap directory..."
sudo mkdir -p "$MAP_DIR"

# Write the keymap file
echo "Writing keymap to $MAP_FILE..."
sudo tee "$MAP_FILE" > /dev/null <<EOF
keycode 29 = Caps_Lock
keycode 58 = Control
EOF

# Load it immediately
echo "Loading custom keymap into current TTY..."
sudo loadkeys "$MAP_FILE"

# Configure vconsole to persist on boot
echo "Setting up /etc/vconsole.conf..."
sudo sed -i '/^KEYMAP=/d' /etc/vconsole.conf 2>/dev/null || true
echo "KEYMAP=custom/${KEYMAP_NAME}" | sudo tee -a /etc/vconsole.conf > /dev/null

# Suggest mkinitcpio (optional but clean)
echo "If you want this to apply in early boot (initramfs), you can run:"
echo "  sudo mkinitcpio -P"

echo "Done. Keymap swapped: Caps Lock is now Control, and Control is now Caps Lock (in TTY)."
