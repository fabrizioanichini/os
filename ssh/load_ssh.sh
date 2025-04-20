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

# Background decryption
openssl enc -d -aes-256-cbc -pbkdf2 -in "$KEY" -out "$FIFO" &
ssh-add "$FIFO"

rm -f "$FIFO"
