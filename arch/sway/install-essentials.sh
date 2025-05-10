#!/bin/bash

set -e

PACKAGES=(
  brightnessctl
  gammastep
  wl-clipboard
  wtype
  sway
  swaybg
  wezterm
  autotiling
)

echo "Updating system..."
sudo pacman -Syu --noconfirm

echo "Installing packages: ${PACKAGES[*]}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "All packages installed successfully."
