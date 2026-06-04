# Secrets

This directory holds SOPS-encrypted runtime secrets.

Its purpose is stewardship: keep sensitive material out of the Nix store, out of plaintext Git history, and out of the small accidents that happen when a tired maintainer is moving too quickly.

## What It Controls

- `secrets/hosts-<host>.yaml` for host-level secrets and host-local root passwords
- `secrets/users-<name>.yaml` for normal-user passwords and outbound SSH identities
- SOPS material decrypted at rebuild or activation time

## Expected Shapes

Host files such as `secrets/hosts-solanine.yaml` own host authority: root's
host-local recovery password, host OpenSSH server keys, and service secrets
whose failure belongs to that machine.

```yaml
users:
  root:
    password: "plain text root password"
    password-hash: "$y$j9T$..."
ssh:
  host:
    ssh_host_ed25519_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    ssh_host_ed25519_key.pub: ssh-ed25519 AAAA... root@solanine
    ssh_host_rsa_key: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
      -----END OPENSSH PRIVATE KEY-----
    ssh_host_rsa_key.pub: ssh-rsa AAAA... root@solanine
```

User files such as `secrets/users-vicky.yaml` own normal login principal
material: password maintenance inputs, activation password hashes, outbound SSH
identities used by Home Manager, and user data recovery keys such as Firefox
backup identities.

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
firefox-backup-age-identity: AGE-SECRET-KEY-...
```

Create or edit encrypted files from the repository root with
repository-relative paths, not `/secrets/...`:

```bash
sops edit secrets/hosts-solanine.yaml
sops edit secrets/users-admin.yaml
sops edit secrets/users-vicky.yaml
```

After creating a new secret file, add it to Git before rebuilding; a flake
cannot evaluate a file it cannot see.

Per-user SSH secrets are not host OpenSSH server secrets. They restore a normal
user's outbound identity for SSH clients, Git remotes, and Git commit signing.
A host may expose these SOPS secrets to a selected Home Manager profile without
enabling `theorem.nixos.base.ssh`. Host SSH keys belong in
`secrets/hosts-<host>.yaml` and are only useful when the system OpenSSH server
is selected.

The Nix wiring expects the prefixed files directly. When migrating old encrypted
files, create the new prefixed files, add them to Git, and only then evaluate
the flake. There is no legacy fallback; missing prefixed files are a repair
fault, not a silent compatibility mode.

Firefox backup encryption uses the selected user's
`firefox-backup-age-identity` to derive that user's recipient. The resulting
archives are intentionally centered on that user. Admin does not receive a
separate recovery recipient for another user's Firefox backup archives.

## Bootstrap Rite

1. Create the SOPS host/user key outside Git:
   `mkdir -p /nix/persist/secrets/sops/age && age-keygen -o /nix/persist/secrets/sops/age/keys.txt`
2. Replace the placeholder recipient in `.sops.yaml` with:
   `age-keygen -y /nix/persist/secrets/sops/age/keys.txt`
3. Generate a dedicated Firefox backup identity for each user who enables the
   backup tool:
   `age-keygen -o /tmp/firefox-backup-vicky-age-identity`
4. Create `secrets/hosts-solanine.yaml` with host material and encrypt it with SOPS:
   `sops secrets/hosts-solanine.yaml`
5. Add the existing OpenSSH host keys to `secrets/hosts-solanine.yaml` before switching to an
   ephemeral root/home, so SOPS recreates them under `/nix/persist/etc/ssh`:
   `sudo cat /etc/ssh/ssh_host_ed25519_key`
   `sudo cat /etc/ssh/ssh_host_ed25519_key.pub`
   `sudo cat /etc/ssh/ssh_host_rsa_key`
   `sudo cat /etc/ssh/ssh_host_rsa_key.pub`
6. Add the encrypted file to Git before rebuilding:
   `git add secrets/hosts-solanine.yaml`

Do not commit plaintext age identity files.

## Password Secrets

For readability, keep plaintext login passwords encrypted beside their
activation hashes. Normal users belong in `secrets/users-<name>.yaml`:

```yaml
users:
  vicky:
    password: "plain text password"
    password-hash: "$y$j9T$..."
```

Root belongs in the selected host file, such as `secrets/hosts-solanine.yaml`:

```yaml
users:
  root:
    password: "plain text root password"
    password-hash: "$y$j9T$..."
```

Regenerate the activation hash after changing a password:

```bash
bash scripts/update-password-hash vicky
bash scripts/update-password-hash root secrets/hosts-solanine.yaml
```

NixOS consumes `users.<name>.password-hash` through `hashedPasswordFile`; the
plaintext entries are only maintenance inputs. Add the hash before running
`nixos-rebuild switch`; it is required for early user creation.

Codex and other agents should not edit encrypted secret payload files directly.
The maintainer should perform SOPS migrations and password changes with
`sops edit` or the password hash script, then add the encrypted files to Git.

## Failure Modes

- Missing `/nix/persist/secrets/sops/age/keys.txt` means SOPS cannot decrypt the protected material.
- Missing OpenSSH host keys can make a rebuilt host look unfamiliar to clients, which is correct and also annoying.
- Missing password hash secrets can break early user creation during activation.
- Missing prefixed files can stop flake evaluation before activation, which is
  correct: the theorem is missing declared protected state.
- Plaintext age identities or private SSH keys in Git are an incident, not a warning. Rotate the exposed material and repair deliberately.

## Maintenance Reminders

After changing encrypted password inputs, regenerate the hash secrets before rebuilding:

```bash
bash scripts/update-password-hash vicky
bash scripts/update-password-hash root secrets/hosts-solanine.yaml
```

Rebuild after updating encrypted files. The machine cannot obey a theorem it has not evaluated.
