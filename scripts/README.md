# Scripts

This directory holds small maintenance rites that are safer as repeatable commands than as remembered shell fragments.

## Available Scripts

- `update-password-hash` decrypts an encrypted plaintext password from a SOPS file, regenerates a yescrypt hash with `mkpasswd`, and writes the hash back into the encrypted file.

## Usage

```bash
scripts/update-password-hash root
scripts/update-password-hash vicky
```

Pass a second argument to use a different encrypted secrets file:

```bash
scripts/update-password-hash vicky secrets/solanine.yaml
```

## Failure Modes

- The script requires `sops` and `mkpasswd` in the execution environment.
- The SOPS key must be available, or decryption will fail before any repair can happen.
- The target account must already have a plaintext password entry at `users.<name>.password`.

## Maintenance Reminders

Run this after changing encrypted login passwords and before rebuilding. Early user creation needs the hash secret; the plaintext entry is only the maintenance input.
