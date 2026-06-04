# Scripts

This directory holds small maintenance rites that are safer as repeatable commands than as remembered shell fragments.

## Available Scripts

- `update-password-hash` decrypts an encrypted plaintext password from a SOPS file, regenerates a yescrypt hash with `mkpasswd`, and writes the hash back into the encrypted file.

## Usage

```bash
scripts/update-password-hash vicky
scripts/update-password-hash root secrets/hosts-solanine.yaml
```

Normal users default to `secrets/users-<name>.yaml`. Root is host-local, so
pass the host secrets file explicitly:

```bash
scripts/update-password-hash admin
scripts/update-password-hash mattia
scripts/update-password-hash root secrets/hosts-firelink.yaml
```

## Failure Modes

- The script requires `sops` and `mkpasswd` in the execution environment.
- The SOPS key must be available, or decryption will fail before any repair can happen.
- The target account must already have a plaintext password entry at `users.<name>.password`.
- `root` has no default file; choosing the host recovery password is an explicit act.

## Maintenance Reminders

Run this after changing encrypted login passwords and before rebuilding. Early user creation needs the hash secret; the plaintext entry is only the maintenance input.
