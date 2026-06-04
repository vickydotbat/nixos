# Per-User Secret Files

## Purpose

Normal-user login passwords and outbound SSH identities should move with the
user account, not with a single host. A maintainer should be able to rotate a
selected user's password once and have every host that selects that user consume
the same encrypted account material.

Root remains host-local. A root password is part of the host's recovery
authority, and it should not become portable user doctrine.

## Chosen Boundary

Use one prefixed SOPS file per normal login principal:

- `secrets/users-admin.yaml`
- `secrets/users-vicky.yaml`
- `secrets/users-mattia.yaml`

Host files remain host-owned:

- `secrets/hosts-solanine.yaml`
- `secrets/hosts-firelink.yaml`

The user file owns normal-user account secrets:

```yaml
users:
  vicky:
    password: "plain text password"
    password-hash: "$y$j9T$..."
ssh:
  vicky:
    id_ed25519: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    id_ed25519.pub: ssh-ed25519 AAAA... comment
```

The host file owns host and root secrets:

```yaml
users:
  root:
    password: "host-local root password"
    password-hash: "$y$j9T$..."
ssh:
  host:
    ssh_host_ed25519_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
```

This keeps the authority legible: a host that can decrypt a selected user's
file can restore that user's login hash and outbound SSH identity. That is
ordinary account administration in this repository. Host SSH keys, service
credentials, and root recovery state stay with the host.

## Repository Changes

Update each normal user registry entry under `users/<name>/default.nix` to point
at a single account secret file, for example:

```nix
secrets.sopsFile = ../../secrets/users-vicky.yaml;
```

The existing SSH fields can then use that account secret file instead of
`../../secrets/ssh-vicky.yaml`. Password hash declarations should use the same
file for normal users.

Keep `passwordHashSecret = "users/<name>/password-hash"` unchanged. The runtime
path remains `/run/secrets-for-users/users/<name>/password-hash`, so
`users.users.<name>.hashedPasswordFile` keeps the same activation contract.

Update `hosts/<host>/secrets.nix` so:

- selected normal-user password hash secrets set `sopsFile = user.secrets.sopsFile`
- selected normal-user SSH secrets set `sopsFile = user.secrets.sopsFile`
- `root.hashedPasswordFile` remains sourced from the host default SOPS file
- host OpenSSH server keys remain sourced from the host default SOPS file

Update `.sops.yaml` creation rules to cover the prefixed account and host
files. Each user file's recipients should match the hosts allowed to administer
that account:

- `secrets/users-admin.yaml`: `solanine` and `firelink`
- `secrets/users-vicky.yaml`: `solanine`
- `secrets/users-mattia.yaml`: `firelink`

Each host file should be decryptable only by that host unless a deliberate
recovery recipient is added:

- `secrets/hosts-solanine.yaml`: `solanine`
- `secrets/hosts-firelink.yaml`: `firelink`

Update `scripts/update-password-hash` so normal users default to
`secrets/users-<account>.yaml`, while root continues to use an explicit host
file. A safe command shape is:

```bash
bash scripts/update-password-hash vicky
bash scripts/update-password-hash root secrets/hosts-solanine.yaml
```

Root should require an explicit host file in this change. Hidden host selection
would be the wrong kind of convenience.

Update `secrets/README.md` to document the new file boundary, the account file
shape, and the migration from `secrets/ssh-<user>.yaml`.

## Migration

For each existing user SSH file:

1. Create the new user file with `sops edit secrets/users-<user>.yaml`.
2. Move that user's `ssh.<user>.*` entries into the new file.
3. Move that user's `users.<user>.password` and `users.<user>.password-hash`
   entries from host files into the new file.
4. Move host-owned material from `secrets/<host>.yaml` into
   `secrets/hosts-<host>.yaml`, including `users.root.*`, host OpenSSH keys,
   and host service secrets.
5. Add the new encrypted files to Git before evaluating the flake.
6. Remove old `secrets/ssh-<user>.yaml` and `secrets/<host>.yaml` files only
   after Nix evaluation proves
   no host references them.

The migration should preserve encrypted material without exposing plaintext in
the working tree. Use `sops` operations, not manual decrypted copies.

## Failure Modes

- If a selected user's new SOPS file is missing or untracked, flake evaluation
  can fail before activation.
- If a password hash is absent from the user file, activation can fail while
  creating users because `neededForUsers = true` secrets are required early.
- If `.sops.yaml` does not grant the target host recipient, the host will build
  a theorem it cannot decrypt.
- If old `ssh-<user>.yaml` files remain referenced, password and SSH rotation
  will be split again.
- If root is moved into a user file by accident, host recovery authority becomes
  less local and less clear.

## Verification

Run targeted checks before any switch:

```bash
rg -n 'ssh-[a-z]+\.yaml|secrets/(users|hosts)-[a-z]+\.yaml|passwordHashSecret|sopsFile' \
  .sops.yaml hosts users scripts secrets/README.md
nix eval --json .#nixosConfigurations.solanine.config.sops.secrets --apply builtins.attrNames
nix eval --json .#nixosConfigurations.firelink.config.sops.secrets --apply builtins.attrNames
nix flake check
nixos-rebuild dry-build --flake .#solanine
nixos-rebuild dry-build --flake .#firelink
```

The rebuild commands should run in the actual NixOS execution context for each
host. If a non-NixOS machine is only editing the repository, use targeted
`nix eval` there and run the dry-build on the NixOS host or deployment driver.
