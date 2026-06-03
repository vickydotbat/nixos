# Secrets

This directory holds SOPS-encrypted runtime secrets.

Its purpose is stewardship: keep sensitive material out of the Nix store, out of plaintext Git history, and out of the small accidents that happen when a tired maintainer is moving too quickly.

## What It Controls

- `secrets/solanine.yaml` for host-level secrets used by `solanine`
- `secrets/ssh-admin.yaml` for `admin` SSH identity material
- `secrets/ssh-vicky.yaml` for `vicky` SSH identity restoration
- encrypted password inputs used to regenerate activation hashes
- SOPS material decrypted at rebuild or activation time

## Expected Shapes

The Firefox backup and SSH host key mechanisms expect `secrets/solanine.yaml` to contain:

```yaml
firefox-backup-age-identity: AGE-SECRET-KEY-...
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

Per-user SSH secret files are selected from `users/<name>/default.nix` and must
match `.sops.yaml` creation rules. Create or edit them from the repository root
with a repository-relative path, not `/secrets/...`:

```bash
sops edit secrets/ssh-admin.yaml
sops edit secrets/ssh-vicky.yaml
```

After creating a new per-user secret file, add it to Git before rebuilding; a
flake cannot evaluate a file it cannot see.

The SSH key mechanism expects `secrets/ssh-<user>.yaml` to contain:

```yaml
ssh:
    <user>:
        id_ed25519: |
            -----BEGIN OPENSSH PRIVATE KEY-----
            ...
            -----END OPENSSH PRIVATE KEY-----
        id_ed25519.pub: ssh-ed25519 AAAA... comment
```

For example, `secrets/ssh-admin.yaml` should use `ssh.admin.id_ed25519` and
`ssh.admin.id_ed25519.pub`. Admin's Home Manager profile is deliberately
minimal: it restores these keys into `/home/admin/.ssh` and configures Git for
repository repair, without enabling Vicky's working surface.

## Bootstrap Rite

1. Create the SOPS host/user key outside Git:
   `mkdir -p /nix/persist/secrets/sops/age && age-keygen -o /nix/persist/secrets/sops/age/keys.txt`
2. Replace the placeholder recipient in `.sops.yaml` with:
   `age-keygen -y /nix/persist/secrets/sops/age/keys.txt`
3. Generate a dedicated Firefox backup identity:
   `age-keygen -o /tmp/firefox-backup-age-identity`
4. Create `secrets/solanine.yaml` with the private identity and encrypt it with SOPS:
   `sops secrets/solanine.yaml`
5. Add the existing OpenSSH host keys to `secrets/solanine.yaml` before switching to an
   ephemeral root/home, so SOPS recreates them under `/nix/persist/etc/ssh`:
   `sudo cat /etc/ssh/ssh_host_ed25519_key`
   `sudo cat /etc/ssh/ssh_host_ed25519_key.pub`
   `sudo cat /etc/ssh/ssh_host_rsa_key`
   `sudo cat /etc/ssh/ssh_host_rsa_key.pub`
6. Add the encrypted file to Git before rebuilding:
   `git add secrets/solanine.yaml`

Do not commit plaintext age identity files.

## Password Secrets

For readability, keep plaintext login passwords encrypted under:

```yaml
users:
  root:
    password: "plain text password"
  vicky:
    password: "plain text password"
```

Regenerate the activation hash after changing either password:

```bash
bash scripts/update-password-hash root
bash scripts/update-password-hash vicky
```

NixOS consumes `users.<name>.password-hash` through `hashedPasswordFile`; the plaintext entries are only maintenance inputs.
Add both `users.root.password-hash` and `users.vicky.password-hash` before running `nixos-rebuild switch`; they are required for early user creation.

## Failure Modes

- Missing `/nix/persist/secrets/sops/age/keys.txt` means SOPS cannot decrypt the protected material.
- Missing OpenSSH host keys can make a rebuilt host look unfamiliar to clients, which is correct and also annoying.
- Missing password hash secrets can break early user creation during activation.
- Plaintext age identities or private SSH keys in Git are an incident, not a warning. Rotate the exposed material and repair deliberately.

## Maintenance Reminders

After changing encrypted password inputs, regenerate the hash secrets before rebuilding:

```bash
bash scripts/update-password-hash root
bash scripts/update-password-hash vicky
```

Rebuild after updating encrypted files. The machine cannot obey a theorem it has not evaluated.
