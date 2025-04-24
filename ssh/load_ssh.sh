#!/bin/sh

set -e

PROFILE="$1"
BASE_DIR="$(dirname "$0")/$PROFILE"
KEY="$BASE_DIR/id_ed25519.enc"
GITCONFIG_SRC="$BASE_DIR/.gitconfig"
GITCONFIG_DEST="$HOME/.gitconfig"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY_DEST="$SSH_DIR/id_ed25519"

if [ -z "$PROFILE" ]; then
  echo "❌ No profile provided. Usage: $0 <profile-name>"
  exit 1
fi

if [ ! -f "$KEY" ]; then
  echo "❌ No encrypted key found at: $KEY"
  exit 1
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

exec < /dev/tty
echo "🔐 Enter passphrase to decrypt SSH key for profile: $PROFILE"

if [ -f "$PRIVATE_KEY_DEST" ]; then
  mv "$PRIVATE_KEY_DEST" "$PRIVATE_KEY_DEST.bak"
  echo "📦 Existing SSH key backed up to: $PRIVATE_KEY_DEST.bak"
fi

openssl enc -d -aes-256-cbc -pbkdf2 -in "$KEY" -out "$PRIVATE_KEY_DEST"
chmod 600 "$PRIVATE_KEY_DEST"
echo "✅ Decrypted SSH key written to: $PRIVATE_KEY_DEST"

if pgrep -u "$USER" ssh-agent > /dev/null; then
  ssh-add "$PRIVATE_KEY_DEST"
  echo "🧠 SSH key added to ssh-agent"
else
  echo "⚠️  ssh-agent not running — key loaded but not added to agent"
fi

if [ -f "$GITCONFIG_SRC" ]; then
  if [ -f "$GITCONFIG_DEST" ]; then
    cp "$GITCONFIG_DEST" "$GITCONFIG_DEST.bak"
    echo "📦 Existing .gitconfig backed up as ~/.gitconfig.bak"
  fi
  cp "$GITCONFIG_SRC" "$GITCONFIG_DEST"
  echo "🧩 Copied Git profile to: $GITCONFIG_DEST"
else
  echo "⚠️  No .gitconfig found for profile: $PROFILE"
fi
