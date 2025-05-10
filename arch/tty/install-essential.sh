#!/bin/bash

set -e

PACKAGES=(
  neovim
  tmux
  man-db
  iwd
  stow
  openssh
  fzf
  docker
)

echo "Updating system..."
sudo pacman -Syu --noconfirm

echo "Installing packages: ${PACKAGES[*]}"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Enabling and starting iwd service..."
sudo systemctl enable iwd
sudo systemctl start iwd

echo "Enabling and starting Docker service..."
sudo systemctl enable docker

echo "All packages installed successfully. run sudo systemctl start docker after process end"
