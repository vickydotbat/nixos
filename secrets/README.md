# Secrets

This directory is for SOPS-encrypted runtime secrets.

The Firefox backup module expects `secrets/solanine.yaml` to contain:

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

The SSH key respawn module expects `secrets/ssh-vicky.yaml` to contain:

```yaml
ssh:
    vicky:
        id_ed25519: |
            -----BEGIN OPENSSH PRIVATE KEY-----
            ...
            -----END OPENSSH PRIVATE KEY-----
        id_ed25519.pub: ssh-ed25519 AAAA... comment
```

Bootstrap outline:

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
