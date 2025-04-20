#!/bin/bash

set -e

PACKAGES=(
  vim
  tmux
  man-db
  iwd
  stow
)

echo "Updating system..."
sudo pacman -Syu --noconfirm

echo "Installing packages: ${PACKAGES[*]}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Enabling and starting iwd service..."
sudo systemctl enable iwd.service
sudo systemctl start iwd.service

echo "All packages installed successfully."
