#!/bin/bash

set -euo pipefail

# Define the base directory
BOOT_ENTRIES="/boot/loader/entries"

# Find the latest non-fallback entry
SOURCE_FILE=$(ls -t ${BOOT_ENTRIES}/*_linux.conf | grep -v "fallback" | head -n 1)

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "❌ No suitable kernel config file found."
  exit 1
fi

echo "✅ Using source: $SOURCE_FILE"

# Paths for new entries
EXTERNAL="${BOOT_ENTRIES}/arch-external.conf"
INTERNAL="${BOOT_ENTRIES}/arch-internal.conf"

# Create external config
sudo awk '
  /^title/ { print "title   Arch Linux (external)"; next }
  /^options/ { print $0 " video=eDP-1:d video=DP-1:3840x2160@60"; next }
  { print }
' "$SOURCE_FILE" | sudo tee "$EXTERNAL" > /dev/null

# Create internal config
sudo awk '
  /^title/ { print "title   Arch Linux (internal)"; next }
  /^options/ { print $0 " video=DP-1:d"; next }
  { print }
' "$SOURCE_FILE" | sudo tee "$INTERNAL" > /dev/null

# Replace loader.conf
sudo tee /boot/loader/loader.conf > /dev/null <<EOF
default arch-internal.conf
timeout 4
EOF

echo "🎉 Bootloader entries created and loader.conf updated."
