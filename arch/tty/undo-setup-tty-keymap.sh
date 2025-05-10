#!/bin/bash
set -e

KEYMAP_NAME="swap-ctrl-caps"
MAP_DIR="/usr/share/kbd/keymaps/custom"
MAP_FILE="${MAP_DIR}/${KEYMAP_NAME}.map"

echo "Reverting keymap changes..."

# Remove custom vconsole config
echo "Restoring default /etc/vconsole.conf..."
sudo sed -i '/^KEYMAP=custom\/'"$KEYMAP_NAME"'/d' /etc/vconsole.conf

# (Optional) Reset to default keymap - usually 'us'
DEFAULT_MAP="us"
echo "Restoring keymap to '$DEFAULT_MAP'..."
sudo loadkeys "$DEFAULT_MAP"

# (Optional) Clean up custom keymap file
if [[ -f "$MAP_FILE" ]]; then
  echo "Removing custom keymap file..."
  sudo rm -f "$MAP_FILE"
fi

# (Optional) Remove empty directory if it exists
if [[ -d "$MAP_DIR" ]]; then
  rmdir --ignore-fail-on-non-empty "$MAP_DIR"
fi

echo "Done! If you want to reset the initramfs stage too, run:"
echo "  sudo mkinitcpio -P"
