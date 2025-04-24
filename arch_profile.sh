#!/bin/bash
set -e

info() {
  echo -e "\n🛠️  $1"
}

info "Changing into arch/ directory..."
cd "$(dirname "$0")/arch"

info "Running install-essential.sh..."
bash install-essential.sh

info "Cloning dotfiles repo..."
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/fabrizioanichini/dotfiles.git "$HOME/dotfiles"
else
  info "dotfiles already cloned. Pulling latest changes..."
  git -C "$HOME/dotfiles" pull
fi

info "Running dotfiles/bootstrap.sh..."
bash "$HOME/dotfiles/bootstrap.sh"

info "✅ dotfiles/bootstrap.sh completed."

echo -e "\n🔔 Please run: \033[1msource ~/.bashrc\033[0m to load the updated shell environment before continuing."
echo -e "Once done, re-run this script with the argument: \033[1mcontinue\033[0m to proceed with SSH setup."

if [[ "$1" == "continue" ]]; then
  info "Resuming setup..."
  info "Running load_ssh.sh for 'personal' profile..."
  bash ../ssh/load_ssh.sh personal
  info "✅ Arch profile setup completed successfully."
else
  exit 0
fi
