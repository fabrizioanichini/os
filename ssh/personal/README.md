# SSH Personal Key Handling (Minimal + POSIX)

A **secure, portable, POSIX-compliant approach to SSH key management** using only standard Unix tools like `openssl`, `ssh-add`, and `mkfifo`.

## Overview

This solution encrypts your private key, keeps the public key readily available, and provides a simple workflow for secure key management directly in your terminal.

## Why This Approach?

Instead of storing private keys unencrypted on disk, this method:

- ✅ Encrypts your SSH key with **AES-256-CBC** using OpenSSL
- ✅ Stores only the **public key** and **encrypted private key** on disk
- ✅ Uses a **named pipe (FIFO)** to decrypt the key on-demand directly into `ssh-agent`
- ✅ Avoids GUI apps, external dependencies, or complex tooling
- ✅ Integrates perfectly with terminal-centric workflows (tmux, Vim, etc.)
- ✅ Follows Unix philosophy: small, focused tools working together

## File Structure

```
ssh/personal/
├── id_ed25519.enc   # Encrypted private key (AES-256-CBC + pbkdf2)
├── id_ed25519.pub   # Public key (safe to share or commit)
└── load_ssh.sh      # Secure decryption and ssh-add script
```

## Usage Guide

### Loading Your SSH Key

When you need to use your SSH key (after login, reboot, or in a new tmux session):

1. Run the script:
   ```sh
   ./load_ssh.sh
   ```

2. Enter your decryption passphrase when prompted

The script will:
- Create a named pipe at `/tmp/decrypted_key` (if it doesn't exist)
- Decrypt `id_ed25519.enc` into the pipe using OpenSSL
- Feed the decrypted key directly into `ssh-add`
- Securely remove the pipe when done

### Creating or Updating Your Encrypted Key

To encrypt a new or updated private key:

```sh
openssl enc -aes-256-cbc -pbkdf2 -salt \
  -in ~/.ssh/id_ed25519 \
  -out ssh/personal/id_ed25519.enc
```

Notes:
- You'll be prompted for a passphrase — store this securely
- The original private key is not modified
- After verifying your encrypted backup works, you can delete the original unencrypted key

## How It Works

### Decryption Process

The `load_ssh.sh` script uses one of two methods:

**Direct piping:**
```sh
openssl enc -d -aes-256-cbc -pbkdf2 \
  -in id_ed25519.enc \
  | ssh-add -
```

**Or with FIFO (preferred method):**
```sh
mkfifo /tmp/decrypted_key
openssl enc -d -aes-256-cbc -pbkdf2 -in id_ed25519.enc -out /tmp/decrypted_key &
ssh-add /tmp/decrypted_key
rm /tmp/decrypted_key
```

### Security Benefits

This approach ensures:
- ✅ The private key is never written to disk in decrypted form
- ✅ No temporary files remain after usage
- ✅ Works reliably in scripts, systemd user services, or terminal startup files

## Requirements

- `openssl` (any recent version with `-pbkdf2` support)
- `ssh-agent` running (can be started via `.zprofile` or manually)
- POSIX-compatible shell (sh, dash, bash, zsh, etc.)

## Integration Ideas

- Add to `.zprofile` or `.bashrc` to load keys automatically at login
- Create a systemd user service to load keys on boot
- Add to tmux configuration to ensure keys are available in all sessions
