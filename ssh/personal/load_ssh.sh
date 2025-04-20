#!/bin/sh

KEY_ENC_PATH="$HOME/.ssh/id_ed25519.enc"
FIFO_PATH="/tmp/decrypted_key"

[ -p "$FIFO_PATH" ] || mkfifo "$FIFO_PATH"

# Background: decrypt the key
openssl enc -d -aes-256-cbc -pbkdf2 -in "$KEY_ENC_PATH" -out "$FIFO_PATH" &

# Add to agent
ssh-add "$FIFO_PATH"

# Clean up
rm -f "$FIFO_PATH"
