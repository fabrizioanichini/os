# SSH Profile Loader

This script allows you to easily switch between different SSH and Git profiles by loading encrypted SSH keys and their associated Git configurations.

## Overview

`load_ssh.sh` helps developers who work with multiple Git identities (personal, work, client projects, etc.) by:

1. Decrypting and loading a profile-specific SSH key
2. Installing the corresponding Git configuration
3. Adding the SSH key to your ssh-agent (if running)

## Prerequisites

- OpenSSL installed on your system
- SSH client installed
- Basic directory structure (explained below)

## Directory Structure

For each profile, create a directory with:

```
<script_location>/<profile_name>/
├── id_ed25519.enc      # Encrypted SSH private key
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

- SSH keys remain encrypted at rest
- Keys are decrypted only when needed
- Passphrase required for decryption
- Proper permissions are enforced on SSH files
- Existing keys/configs are automatically backed up

## What It Does

When run, the script:

1. Validates that a profile name was provided
2. Checks that the encrypted key exists
3. Creates the SSH directory if it doesn't exist
4. Prompts for the decryption passphrase
5. Backs up any existing SSH key
6. Decrypts the profile's SSH key
7. Sets appropriate permissions (600) on the key
8. Adds the key to ssh-agent if it's running
9. Backs up and replaces your Git configuration (if provided)

## Backup Behavior

The script automatically creates backups:
- Existing SSH keys are backed up to `~/.ssh/id_ed25519.bak`
- Existing Git configs are backed up to `~/.gitconfig.bak`

## Creating New Profiles

To create a new profile:

1. Create a directory with your profile name
2. Generate and encrypt your SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   openssl enc -aes-256-cbc -pbkdf2 -in ~/.ssh/id_ed25519 -out /path/to/profile/id_ed25519.enc
   ```
3. Add your Git configuration to the profile directory

## Notes

- Currently supports Ed25519 keys only
- Only one SSH key is loaded at a time
- Requires interactive terminal for passphrase entry

## Troubleshooting

- **"No profile provided"**: You need to specify a profile name
- **"No encrypted key found"**: Check if the key exists at the expected location
- **"ssh-agent not running"**: Start ssh-agent with `eval "$(ssh-agent -s)"`
