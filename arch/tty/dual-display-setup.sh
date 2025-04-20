#!/bin/bash
# Arch Linux Dual-Display Boot Configuration Script
# This script automates the setup of dual boot entries for handling internal and external displays

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display script usage
usage() {
    echo -e "${BLUE}Arch Linux Dual-Display Boot Configuration Script${NC}"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help                 Show this help message"
    echo "  -r, --root-uuid UUID       Specify root partition UUID"
    echo "  -i, --internal DEVICE      Specify internal display (default: eDP-1)"
    echo "  -e, --external DEVICE      Specify external display (default: auto-detect)"
    echo "  -d, --detect-only          Only detect displays without making changes"
    echo "  -y, --yes                  Non-interactive mode (answer yes to all prompts)"
}

# Function to detect connected displays
detect_displays() {
    echo -e "${BLUE}Detecting connected displays...${NC}"
    
    # Find all potential display outputs
    displays=$(find /sys/class/drm -name "card[0-9]*-*" -type d | grep -v "/card[0-9]*-[0-9]*$")
    
    echo -e "${YELLOW}Display status:${NC}"
    for display in $displays; do
        if [ -f "$display/status" ]; then
            status=$(cat "$display/status")
            name=$(basename "$display")
            
            # Format name to standard format (card1-HDMI-A-1 → HDMI-A-1)
            name=$(echo "$name" | sed -E 's/card[0-9]*-//')
            
            if [ "$status" = "connected" ]; then
                echo -e "  ${GREEN}$name${NC}: $status"
                
                # Try to get resolution if possible
                if [ -f "$display/modes" ]; then
                    best_mode=$(cat "$display/modes" | head -1)
                    echo -e "    Best mode: ${YELLOW}$best_mode${NC}"
                fi
                
                # Auto-detect external display if not manually specified
                if [ "$status" = "connected" ] && [ "$name" != "$INTERNAL_DISPLAY" ] && [ -z "$EXTERNAL_DISPLAY" ]; then
                    EXTERNAL_DISPLAY="$name"
                    DETECTED_EXTERNAL=true
                fi
            else
                echo -e "  ${RED}$name${NC}: $status"
            fi
        fi
    done
    
    echo
    if [ "$DETECTED_EXTERNAL" = true ]; then
        echo -e "${GREEN}Auto-detected external display: $EXTERNAL_DISPLAY${NC}"
    fi
}

# Function to get root partition UUID if not provided
get_root_uuid() {
    if [ -z "$ROOT_UUID" ]; then
        # Try to get the UUID from the current system
        current_root=$(findmnt -no SOURCE /)
        if [[ "$current_root" == *"UUID="* ]]; then
            ROOT_UUID=$(echo "$current_root" | sed -E 's/.*UUID=([a-f0-9-]+).*/\1/')
        elif [[ "$current_root" == *"PARTUUID="* ]]; then
            ROOT_UUID=$(echo "$current_root" | sed -E 's/.*PARTUUID=([a-f0-9-]+).*/\1/')
            ROOT_UUID_TYPE="PARTUUID"
        elif [[ "$current_root" == /dev/* ]]; then
            # Get UUID from device
            if command -v blkid > /dev/null; then
                ROOT_UUID=$(blkid -s UUID -o value "$current_root")
            fi
        fi
        
        if [ -n "$ROOT_UUID" ]; then
            echo -e "${GREEN}Detected root UUID: $ROOT_UUID${NC}"
        else
            echo -e "${RED}Could not detect root UUID automatically.${NC}"
            echo -e "${YELLOW}Please provide it using the -r option.${NC}"
            exit 1
        fi
    fi
}

# Function to create boot entries
create_boot_entries() {
    echo -e "${BLUE}Creating boot entries...${NC}"
    
    # Path to boot entries
    ENTRIES_DIR="/boot/loader/entries"
    
    # Ensure the directory exists
    if [ ! -d "$ENTRIES_DIR" ]; then
        echo -e "${RED}Error: $ENTRIES_DIR does not exist.${NC}"
        echo "Make sure systemd-boot is installed and set up correctly."
        exit 1
    fi
    
    # Get kernel and initramfs filenames
    KERNEL=$(ls /boot/vmlinuz-* | head -1 | xargs basename)
    INITRAMFS=$(ls /boot/initramfs-linux*.img | head -1 | xargs basename)
    
    # If we couldn't find the kernel files, use defaults
    if [ -z "$KERNEL" ]; then KERNEL="vmlinuz-linux"; fi
    if [ -z "$INITRAMFS" ]; then INITRAMFS="initramfs-linux.img"; fi
    
    echo "Using kernel: $KERNEL"
    echo "Using initramfs: $INITRAMFS"
    
    # Create external display configuration
    echo -e "${YELLOW}Creating external display configuration...${NC}"
    cat > "$ENTRIES_DIR/arch-external.conf" << EOF
title   Arch Linux (external)
linux   /$KERNEL
initrd  /$INITRAMFS
options root=${ROOT_UUID_TYPE:-UUID}=$ROOT_UUID rw rootfstype=ext4 video=$INTERNAL_DISPLAY:d video=$EXTERNAL_DISPLAY:3840x2160@60
EOF
    echo -e "${GREEN}Created $ENTRIES_DIR/arch-external.conf${NC}"
    
    # Create internal display configuration
    echo -e "${YELLOW}Creating internal display configuration...${NC}"
    cat > "$ENTRIES_DIR/arch-internal.conf" << EOF
title   Arch Linux (internal)
linux   /$KERNEL
initrd  /$INITRAMFS
options root=${ROOT_UUID_TYPE:-UUID}=$ROOT_UUID rw rootfstype=ext4 video=$EXTERNAL_DISPLAY:d
EOF
    echo -e "${GREEN}Created $ENTRIES_DIR/arch-internal.conf${NC}"
    
    # Configure default boot option if loader.conf exists
    if [ -f "/boot/loader/loader.conf" ]; then
        echo -e "${YELLOW}Updating boot loader configuration...${NC}"
        
        # Check if default entry already exists
        if grep -q "^default " "/boot/loader/loader.conf"; then
            # Update existing default entry
            sed -i 's/^default .*/default arch-internal.conf/' "/boot/loader/loader.conf"
        else
            # Add default entry
            echo "default arch-internal.conf" >> "/boot/loader/loader.conf"
        fi
        
        # Check if timeout already exists
        if grep -q "^timeout " "/boot/loader/loader.conf"; then
            # Update existing timeout
            sed -i 's/^timeout .*/timeout 4/' "/boot/loader/loader.conf"
        else
            # Add timeout entry
            echo "timeout 4" >> "/boot/loader/loader.conf"
        fi
        
        echo -e "${GREEN}Updated /boot/loader/loader.conf${NC}"
    else
        echo -e "${YELLOW}Warning: /boot/loader/loader.conf does not exist.${NC}"
        echo "Consider creating it with the following content:"
        echo "default arch-internal.conf"
        echo "timeout 4"
    fi
}

# Function to create recovery script
create_recovery_script() {
    echo -e "${BLUE}Creating recovery script...${NC}"
    
    cat > "/usr/local/bin/fix-display-boot.sh" << EOF
#!/bin/bash
# Display boot configuration recovery script

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Restoring internal display boot configuration..."
cp /boot/loader/entries/arch-internal.conf /boot/loader/entries/arch.conf
echo -e "\${GREEN}Done! The system will use the internal display on next boot.${NC}"
EOF
    
    chmod +x "/usr/local/bin/fix-display-boot.sh"
    echo -e "${GREEN}Created recovery script at /usr/local/bin/fix-display-boot.sh${NC}"
}

# Default values
INTERNAL_DISPLAY="eDP-1"
EXTERNAL_DISPLAY=""
DETECT_ONLY=false
NON_INTERACTIVE=false
DETECTED_EXTERNAL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--root-uuid)
            ROOT_UUID="$2"
            shift 2
            ;;
        -i|--internal)
            INTERNAL_DISPLAY="$2"
            shift 2
            ;;
        -e|--external)
            EXTERNAL_DISPLAY="$2"
            shift 2
            ;;
        -d|--detect-only)
            DETECT_ONLY=true
            shift
            ;;
        -y|--yes)
            NON_INTERACTIVE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main script execution
echo -e "${BLUE}Arch Linux Dual-Display Boot Configuration${NC}"
echo -e "${YELLOW}This script will configure systemd-boot for dual-display use.${NC}"
echo

# Detect displays
detect_displays

# If detect-only mode, exit here
if [ "$DETECT_ONLY" = true ]; then
    echo -e "${GREEN}Display detection complete. Exiting without making changes.${NC}"
    exit 0
fi

# Verify external display is set
if [ -z "$EXTERNAL_DISPLAY" ]; then
    echo -e "${RED}Error: No external display detected or specified.${NC}"
    echo "Please connect an external display or specify one using the -e option."
    exit 1
fi

# Get root UUID if not provided
get_root_uuid

# Confirmation before proceeding
if [ "$NON_INTERACTIVE" = false ]; then
    echo -e "${YELLOW}Configuration summary:${NC}"
    echo "  Internal display: $INTERNAL_DISPLAY"
    echo "  External display: $EXTERNAL_DISPLAY"
    echo "  Root UUID: $ROOT_UUID"
    echo "  Root UUID type: ${ROOT_UUID_TYPE:-UUID}"
    echo
    read -p "Continue with these settings? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted.${NC}"
        exit 0
    fi
fi

# Create boot entries
create_boot_entries

# Create recovery script
create_recovery_script

echo
echo -e "${GREEN}Configuration complete!${NC}"
echo -e "${YELLOW}Boot entries created:${NC}"
echo "  - arch-external.conf (for 4K external monitor)"
echo "  - arch-internal.conf (for internal laptop display)"
echo
echo -e "${YELLOW}Recovery instructions:${NC}"
echo "If you boot with the wrong configuration, you can either:"
echo "1. Reboot and select the correct entry from the boot menu"
echo "2. Run the recovery script: /usr/local/bin/fix-display-boot.sh"
echo
echo -e "${BLUE}Enjoy your dual-display setup!${NC}"