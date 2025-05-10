#!/bin/bash

set -e

info() {
  echo -e "\n🛠️  $1"
}

info "Changing into arch/ directory..."
cd "$(dirname "$0")/arch"

info "Running install-essential.sh..."
bash install-essential.sh

info "Running bootloader setup script..."
bash tty/setup-boot-entries.sh

info "Running keymap setup script..."
bash tty/setup-tty-keymap.sh

info "Cloning dotfiles repo..."
if [ ! -d "$HOME/.dotfiles" ]; then
  git clone https://github.com/fabrizioanichini/dotfiles.git "$HOME/.dotfiles"
else
  info "dotfiles already cloned. Pulling latest changes..."
  git -C "$HOME/.dotfiles" pull
fi

info "Running .dotfiles/bootstrap.sh..."
bash "$HOME/.dotfiles/bootstrap.sh"
info "✅ .dotfiles/bootstrap.sh completed."

echo -e "\n🔔 Please run: \033[1msource ~/.bashrc\033[0m to load the updated shell environment before continuing."
echo -e "Once done, re-run this script with the argument: \033[1mcontinue\033[0m to proceed with SSH setup."

if [[ "$1" == "continue" ]]; then
  info "Resuming setup..."
  
  info "Running load_ssh.sh for 'personal' profile..."
  bash ../ssh/load_ssh.sh personal
  
  info "Updating dotfiles repository to use SSH instead of HTTPS..."
  if [ -d "$HOME/.dotfiles" ]; then
    cd "$HOME/.dotfiles"
    git remote set-url origin git@github.com:fabrizioanichini/dotfiles.git
    info "✅ Repository updated to use SSH authentication."
    echo -e "You can now push changes without HTTPS authentication."
  else
    info "⚠️ Dotfiles directory not found at $HOME/.dotfiles."
  fi

  info "Cloning OS project into ~/projects/os..."
  mkdir -p "$HOME/projects"

  if [ ! -d "$HOME/projects/os" ]; then
    git clone git@github.com:fabrizioanichini/os.git "$HOME/projects/os"
    info "✅ OS repo cloned to ~/projects/os."
  else
    info "📁 ~/projects/os already exists. Pulling latest changes..."
    git -C "$HOME/projects/os" pull
  fi

  info "✅ Arch profile setup completed successfully."
else
  exit 0
fi
