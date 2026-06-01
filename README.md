# nixos-configuration

# Reinstallation or Deployment

For reinstall:

1. Restore/keep /nix/persist/secrets/sops/age/keys.txt.
2. Clone this repo with committed secrets/solanine.yaml.
3. Rebuild.
4. sops-nix decrypts firefox-backup-age-identity back into /run/secrets/....
5. firefox-state-restore can decrypt your Firefox archives.
