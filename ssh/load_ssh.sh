#!/bin/sh

PROFILE="$1"
BASE_DIR="$(dirname "$0")/$PROFILE"
KEY="$BASE_DIR/id_ed25519.enc"
FIFO="/tmp/ssh_${PROFILE}_key"

if [ ! -f "$KEY" ]; then
  echo "❌ No encrypted key found for profile: $PROFILE"
  exit 1
fi

[ -p "$FIFO" ] || mkfifo "$FIFO"
chmod 600 "$FIFO"

exec < /dev/tty

# Decrypt the SSH key in the background
openssl enc -d -aes-256-cbc -pbkdf2 -in "$KEY" -out "$FIFO" &
sleep 0.2

# Load the key into ssh-agent
ssh-add "$FIFO"
RESULT=$?

# Remove the temporary FIFO pipe
rm -f "$FIFO"

# Check if the key was added successfully
if [ $RESULT -ne 0 ]; then
  echo "❌ Failed to load SSH key — check passphrase and permissions."
  exit 1
else
  echo "✅ SSH key loaded for profile: $PROFILE"
fi

# Handle .gitconfig for the profile
GITCONFIG_SRC="$BASE_DIR/.gitconfig"
GITCONFIG_DEST="$HOME/.gitconfig"

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
