#!/bin/bash
set -e

# Helper to show status
info() {
  echo -e "\n🛠️  $1"
}

info "Changing into arch/ directory..."
cd "$(dirname "$0")/arch"

# Step 1: Run install-essential.sh
info "Running install-essential.sh..."
bash install-essential.sh

# Step 2: Clone dotfiles and run bootstrap
info "Cloning dotfiles repo..."
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/fabrizioanichini/dotfiles "$HOME/dotfiles"
else
  info "dotfiles already cloned. Pulling latest changes..."
  git -C "$HOME/dotfiles" pull
fi

info "Running dotfiles/bootstrap.sh..."
bash "$HOME/dotfiles/bootstrap.sh"

# Step 3: Load SSH keys
info "Running load_ssh.sh for 'personal' profile..."
bash ssh/load_ssh.sh personal

info "✅ Arch profile setup completed successfully."
