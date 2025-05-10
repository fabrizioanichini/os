#!/bin/bash
set -e

KEYMAP_NAME="swap-ctrl-caps"
MAP_DIR="/usr/share/kbd/keymaps/custom"
MAP_FILE="${MAP_DIR}/${KEYMAP_NAME}.map"

echo "Creating custom keymap directory..."
sudo mkdir -p "$MAP_DIR"

echo "Creating a custom keymap based on 'us.map' (or your layout)..."
cat <<EOF | sudo tee "$MAP_FILE" > /dev/null
keymaps 0-2,4-6,8-9,12
include "linux-with-alt-and-altgr"
include "compose.latin1"
keycode 29 = Caps_Lock
keycode 58 = Control
EOF

echo "Loading keymap..."
sudo loadkeys "$MAP_FILE"

echo "Persisting keymap to /etc/vconsole.conf..."
sudo sed -i '/^KEYMAP=/d' /etc/vconsole.conf 2>/dev/null || true
echo "KEYMAP=custom/${KEYMAP_NAME}" | sudo tee -a /etc/vconsole.conf > /dev/null

echo "Done! If you want to apply it at initramfs stage, run:"
echo "  sudo mkinitcpio -P"
