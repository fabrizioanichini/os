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

# Decrypt in background
openssl enc -d -aes-256-cbc -pbkdf2 -in "$KEY" -out "$FIFO" &
sleep 0.2

# Load into agent
ssh-add "$FIFO"
RESULT=$?

rm -f "$FIFO"

# Optional error check
if [ $RESULT -ne 0 ]; then
  echo "❌ Failed to load SSH key — check passphrase and permissions."
  exit 1
else
  echo "✅ SSH key loaded for profile: $PROFILE"
fi
