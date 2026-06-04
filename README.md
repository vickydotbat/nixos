![banner](./assets/banner.png)

# nixos

This repository declares the NixOS configuration for `solanine`.

Its purpose is not glamour. It is memory: the machine should be rebuilt from
checked-in theorems, persisted secrets, and repeatable rites rather than from
whatever survived the last repair session.

## Beating Heart

Start with [`docs/philosophy.md`](./docs/philosophy.md). It is the repository
doctrine for reproducibility, determinism, host and user boundaries, calibrated
hardening, modularity, documentation, and verification. If a proposed change or
current file shape fights that philosophy, change the shape. Do not bury the
rule in a TODO ledger and keep building around it.

## What It Controls

- NixOS system configuration for `solanine`
- Home Manager configuration for selected users: a full daily-driver profile
  for `vicky`, and a minimal repair profile for `admin`
- local packages and package overlays
- SOPS-managed runtime secrets
- persistence and recovery mechanisms for state that must survive rebuilds

## Reinstallation Or Deployment

For a reinstall, preserve the secret material before asking the forge to
evaluate the system again:

1. Restore or keep `/nix/persist/secrets/sops/age/keys.txt`.
2. Clone this repository, including committed encrypted files such as
   `secrets/solanine.yaml` and per-user SSH files such as
   `secrets/ssh-admin.yaml`.
3. Rebuild the system in the appropriate execution context.
4. Let `sops-nix` decrypt `firefox-backup-age-identity` back into `/run/secrets/...`.
5. Let `firefox-state-restore` decrypt the Firefox archives.

## Failure Modes

- If `/nix/persist/secrets/sops/age/keys.txt` is missing, SOPS cannot decrypt
the repository secrets. The system may still evaluate, but the protected
mechanisms will arrive empty-handed.
- If encrypted secret files are not present in the clone, rebuilds that depend
  on them will fail or produce a machine without the intended state. User SSH
  identities are part of this protected material even when the host does not
  run `sshd`.
- If plaintext identities are committed, stewardship has failed. Remove them,
rotate what was exposed, and repair the history only with deliberate care.

## Maintenance Reminders

Run formatting and flake checks after structural changes. Rebuild only from an execution context you understand: local NixOS host, remote Linux deploy, remote macOS deploy, or another crucible with its own sharp edges.
