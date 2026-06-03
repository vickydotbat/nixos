# Users

This directory holds repository-level user doctrine.

Hosts choose from these declarations. The user tree names the person or account
role, the groups it needs, the password secret it expects, and whether Home
Manager should be forged for it. System modules consume the chosen accounts;
Home Manager modules consume the chosen user's home profile.

## Layout

- `admin/` is the mandatory repair account. It belongs to `wheel` and exists so
  a host has a known administrative handhold even when daily-driver users are
  being recalibrated.
- `guest/` is an opt-in low-access account. It should not receive SSH private
  key material or administrative groups.
- `vicky/` is the current daily-driver user, including her Home Manager profile
  and SSH client settings.

## Home Profile Doctrine

The user profile is where personal Home Manager choices belong: terminal font
scale, clipboard trust, multiplexer key ownership, desktop layout, editor
workflow, language stacks, application autostart, and theme or prompt posture.
Reusable modules under `modules/home/` should expose those as options or carry
small repair-minded defaults. If a setting is only true for one operator and
Home Manager already exposes it directly, set that native option in the user's
profile. Theorem options are for coordinated mechanisms, not renamed copies of
package settings.

## Shared Configuration Access

`admin` and `vicky` both belong to the `nixcfg` group. The group is declared by
`modules/nixos/base/users.nix` so selected users can share stewardship of the
system flake without making either account own the repository alone.
The same module prepares `/nix/nixos` as a `root:nixcfg`
group-writable setgid directory when the system activates.

Group membership is only half the mechanism. Git's ownership check does not
trust a repository merely because the user belongs to the owning group, so the
Home Manager Git profile marks `/nix/nixos` as a safe directory.
A fresh clone also keeps the ownership and mode chosen by the command that
created it. During reinstall or first deployment, clone the repository into its
intended path, then set its owner, group, and write bit before asking Home
Manager users to alter it:

Use the host's active privilege mechanism for the elevated commands below.
`solanine` currently enables the `sudo` security profile. If a host selects the
`run0-sudo` profile instead, `sudo` may be absent or deliberately inert; run the
same commands through `run0`, or through the configured `sudo` alias if that
profile provides one.

```bash
priv=sudo # use run0 on hosts where sudo is disabled

$priv chown -R root:nixcfg /nix/nixos
$priv chmod -R g+rwX /nix/nixos
$priv chmod -R o-rwx /nix/nixos/.git
$priv find /nix/nixos -type d -exec chmod g+s {} +
git -c safe.directory=/nix/nixos -C /nix/nixos config core.sharedRepository group
```

For less handwork, the future spawning rite should either clone as a member of
`nixcfg` with an appropriate umask, or run the ownership calibration immediately
after the clone. The setgid bit keeps new directories under the shared group;
`core.sharedRepository` teaches Git to preserve group write access inside its own
machinery. The `.git` directory should not be world-writable; group stewardship
is the intended mechanism. Without these steps, the group exists but the
repository may still answer only to the account that fetched it, or Git may
refuse the worktree as unsafe.

## SSH Key Doctrine

Use Ed25519 keys for normal user SSH identities unless a specific legacy host
requires another algorithm:

```bash
ssh-keygen -t ed25519 -a 32 -f ~/.ssh/id_ed25519
```

The reusable Home Manager SSH module restores `id_ed25519` and
`id_ed25519.pub` from SOPS-backed secrets, and Vicky's Git/SSH profiles point at
that identity. Keep agent ownership singular per user profile. This repository
uses the OpenSSH agent through `programs.ssh.startAgent`; do not also enable a
competing `gpg-agent` SSH socket unless the user profile is deliberately moved
to that model.

## Failure Modes

- Do not put host hardware, host package choices, or machine-specific secrets
  here. Users describe accounts; hosts decide whether those accounts belong on a
  given machine.
- Do not give a daily-driver account duties that belong to `admin`. Repair needs
  a separate grip when personal configuration is the broken mechanism.
- `admin` owns UID 1000 by doctrine. Daily-driver accounts must use later fixed
  UIDs, and existing persisted files must be migrated by numeric owner before
  activating a host that changes an established user's UID.
