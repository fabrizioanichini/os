# SSH Multi-Profile Key Management

A secure, minimal approach to managing multiple SSH identities with encrypted keys.

## Overview

This system allows you to maintain separate SSH identities (personal, work, client-specific, etc.) with encrypted private keys that are only decrypted when needed and directly loaded into your SSH agent without touching disk in unencrypted form.

## Directory Structure

```
ssh/
├── load_ssh.sh            # Main script for loading keys from any profile
├── personal/              # Personal identity profile
│   ├── README.md          # Profile-specific documentation
│   ├── id_ed25519.enc     # Encrypted private key
│   └── id_ed25519.pub     # Public key (safe to share)
└── tomato/                # Another identity profile (e.g., for a specific client/project)
    ├── README.md          # Profile-specific documentation
    ├── id_ed25519.enc     # Encrypted private key
    └── id_ed25519.pub     # Public key (safe to share)
```

## Security Features

- ✅ Private keys are stored only in encrypted form (AES-256-CBC)
- ✅ Decryption happens on-demand directly into SSH agent
- ✅ Named pipes (FIFOs) ensure keys never touch disk in decrypted form
- ✅ POSIX-compliant using only standard Unix tools
- ✅ Clean separation between different identities

## Usage

### Loading a Key

To load a specific profile's SSH key:

```sh
./load_ssh.sh personal   # Load your personal SSH key
./load_ssh.sh tomato     # Load your tomato project SSH key
```

You'll be prompted for the decryption passphrase, which should be unique for each profile.

### Creating a New Profile

1. Generate a new SSH key:
   ```sh
   ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/temp_key
   ```

2. Create a new profile directory:
   ```sh
   mkdir -p ssh/new_profile
   ```

3. Encrypt the private key:
   ```sh
   openssl enc -aes-256-cbc -pbkdf2 -salt \
     -in ~/.ssh/temp_key \
     -out ssh/new_profile/id_ed25519.enc
   ```

4. Copy the public key:
   ```sh
   cp ~/.ssh/temp_key.pub ssh/new_profile/id_ed25519.pub
   ```

5. Securely delete the unencrypted key:
   ```sh
   shred -u ~/.ssh/temp_key
   ```

## How It Works

The `load_ssh.sh` script:

1. Creates a unique named pipe for the specified profile
2. Decrypts the profile's private key to this pipe in the background
3. Adds the key from the pipe to your SSH agent
4. Removes the pipe when done

This ensures the decrypted key only exists in memory, never on disk.

## Decryption Process

The load_ssh.sh script uses one of two methods:

**Direct piping:**
```bash
openssl enc -d -aes-256-cbc -pbkdf2 \
  -in id_ed25519.enc \
  | ssh-add -
```

**Or with FIFO (preferred method):**
```bash
mkfifo /tmp/decrypted_key
openssl enc -d -aes-256-cbc -pbkdf2 -in id_ed25519.enc -out /tmp/decrypted_key &
ssh-add /tmp/decrypted_key
rm /tmp/decrypted_key
```

## Viewing or Accessing Decrypted Keys

There may be times when you need to view the decrypted private key content or temporarily use it in unencrypted form. Here are secure ways to do so:

### View Key Content Without Writing to Disk

To view the key content in your terminal without saving it to disk:

```bash
# Display the decrypted key in terminal
openssl enc -d -aes-256-cbc -pbkdf2 -in ssh/personal/id_ed25519.enc | cat
```

### Temporarily Decrypt to Use Outside SSH Agent

If you need the decrypted key temporarily:

```bash
# Decrypt to a secured temporary file
openssl enc -d -aes-256-cbc -pbkdf2 \
  -in ssh/personal/id_ed25519.enc \
  -out /tmp/temp_key

# Set proper permissions
chmod 600 /tmp/temp_key

# Use the key for your purpose...

# Securely delete when done
shred -u /tmp/temp_key
```

### Temporarily Place in Standard SSH Location

To temporarily use the key in the standard ~/.ssh location:

```bash
# Decrypt directly to ~/.ssh/id_ed25519
openssl enc -d -aes-256-cbc -pbkdf2 \
  -in ssh/personal/id_ed25519.enc \
  -out ~/.ssh/id_ed25519_personal

# Set proper permissions
chmod 600 ~/.ssh/id_ed25519_personal

# When done, remove it securely
shred -u ~/.ssh/id_ed25519_personal
```

**⚠️ Security Warning:** Remember that having the unencrypted private key anywhere, even temporarily, increases your security risk. Always securely delete unencrypted keys when you're done with them.

## Requirements

- `openssl` with PBKDF2 support
- `ssh-agent` running
- POSIX-compatible shell

## Best Practices

- Use different keys for different contexts (personal, work, clients)
- Use strong, unique passphrases for each profile
- Consider adding a comment to your public keys to identify their purpose:
  ```
  ssh-ed25519 AAAA... user@personal
  ssh-ed25519 AAAA... user@tomato-project
  ```
- Backup your encrypted keys and passphrases securely

## Integration Ideas

- Add aliases to your shell configuration:
  ```sh
  # In .bashrc or .zshrc
  alias ssh-personal="~/path/to/ssh/load_ssh.sh personal"
  alias ssh-tomato="~/path/to/ssh/load_ssh.sh tomato"
  ```

- Create a function to load all profiles:
  ```sh
  load-all-ssh() {
    for profile in personal tomato; do
      ~/path/to/ssh/load_ssh.sh "$profile"
    done
  }
  ```
