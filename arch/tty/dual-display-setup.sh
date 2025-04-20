#!/bin/bash
set -euo pipefail

# === Configuration ===
PARTUUID=$(blkid -s PARTUUID -o value /dev/disk/by-label/root) # or adjust manually
LOADER_ENTRIES_DIR="/boot/loader/entries"
LOADER_CONF="/boot/loader/loader.conf"
FALLBACK_ENTRY="arch-internal.conf"
KERNEL_OPTIONS_BASE="root=PARTUUID=${PARTUUID} rw rootfstype=ext4"

# === Helper Function ===
detect_external_port() {
    echo "[*] Detecting external monitor (DP-x)..."
    for dp in /sys/class/drm/card*-DP-*/status; do
        if grep -q "connected" "$dp"; then
            port=$(basename "$dp" | cut -d- -f2-)
            echo "[+] Found connected external display: $port"
            echo "$port"
            return
        fi
    done
    echo "[!] No external monitor connected. Falling back to default DP-1"
    echo "DP-1"
}

# === Main Script ===

echo "[*] Creating dual boot entries for internal and external display..."

external_port=$(detect_external_port)

# Create external config
cat > "${LOADER_ENTRIES_DIR}/arch-external.conf" <<EOF
title   Arch Linux (external)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options ${KERNEL_OPTIONS_BASE} video=eDP-1:d video=${external_port}:3840x2160@60
EOF

# Create internal config
cat > "${LOADER_ENTRIES_DIR}/arch-internal.conf" <<EOF
title   Arch Linux (internal)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options ${KERNEL_OPTIONS_BASE} video=${external_port}:d
EOF

# Create fallback arch.conf (for safe boot)
cp "${LOADER_ENTRIES_DIR}/arch-internal.conf" "${LOADER_ENTRIES_DIR}/arch.conf"

# Configure systemd-boot default
cat > "$LOADER_CONF" <<EOF
default ${FALLBACK_ENTRY}
timeout 4
EOF

echo "[+] Boot entries created successfully."

# === Recovery Script ===
FIX_SCRIPT_PATH="/usr/local/bin/fix-display-boot.sh"
cat > "$FIX_SCRIPT_PATH" <<'EOF'
#!/bin/bash
cp /boot/loader/entries/arch-internal.conf /boot/loader/entries/arch.conf
echo "Display boot fixed: now using internal display config."
EOF
chmod +x "$FIX_SCRIPT_PATH"

echo "[+] Recovery script installed at $FIX_SCRIPT_PATH"
echo "[✓] Setup complete. Reboot and test the entries."

