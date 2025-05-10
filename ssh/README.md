# SSH Profile Loader

This script allows you to easily switch between different SSH and Git profiles by loading encrypted SSH keys and their associated Git configurations.

## Overview

`load_ssh.sh` helps developers who work with multiple Git identities (personal, work, client projects, etc.) by:

1. Decrypting and loading a profile-specific SSH private key
2. Copying the corresponding public key
3. Installing the corresponding Git configuration
4. Adding the SSH key to your ssh-agent (if running)

## Prerequisites

- OpenSSL installed on your system
- SSH client installed
- Basic directory structure (explained below)

## Directory Structure

For each profile, create a directory with:

```
<script_location>/<profile_name>/
├── id_ed25519.enc      # Encrypted SSH private key
├── id_ed25519.pub      # SSH public key
└── .gitconfig          # Git configuration file (optional)
```

## Usage

```bash
./load_ssh.sh <profile-name>
```

For example:
```bash
./load_ssh.sh work
./load_ssh.sh personal
./load_ssh.sh client-xyz
```

## Security Features

- SSH private keys remain encrypted at rest
- Keys are decrypted only when needed
- Passphrase required for decryption
- Proper permissions are enforced on SSH files (600 for private key, 644 for public key)
- Existing keys/configs are automatically backed up

## What It Does

When run, the script:

1. Validates that a profile name was provided
2. Checks that the encrypted key exists
3. Creates the SSH directory if it doesn't exist
4. Prompts for the decryption passphrase
5. Backs up any existing SSH keys (both private and public)
6. Decrypts the profile's SSH private key
7. Copies the profile's public key (if available)
8. Sets appropriate permissions on both keys
9. Adds the key to ssh-agent if it's running
10. Backs up and replaces your Git configuration (if provided)

## Backup Behavior

The script automatically creates backups:
- Existing SSH private keys are backed up to `~/.ssh/id_ed25519.bak`
- Existing SSH public keys are backed up to `~/.ssh/id_ed25519.pub.bak`
- Existing Git configs are backed up to `~/.gitconfig.bak`

## Creating New Profiles

To create a new profile:

1. Create a directory with your profile name
2. Generate an SSH key pair:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
3. Encrypt your private key:
   ```bash
   openssl enc -aes-256-cbc -pbkdf2 -in ~/.ssh/id_ed25519 -out /path/to/profile/id_ed25519.enc
   ```
4. Copy your public key to the profile directory:
   ```bash
   cp ~/.ssh/id_ed25519.pub /path/to/profile/
   ```
5. Add your Git configuration to the profile directory

## Notes

- Currently supports Ed25519 keys only
- Only one SSH key pair is loaded at a time
- Requires interactive terminal for passphrase entry
- Public key copying is optional (will work without it)

## Troubleshooting

- **"No profile provided"**: You need to specify a profile name
- **"No encrypted key found"**: Check if the key exists at the expected location
- **"No public key found"**: The script will still work, but you may want to add the public key to your profile
- **"ssh-agent not running"**: Start ssh-agent with `eval "$(ssh-agent -s)"`
