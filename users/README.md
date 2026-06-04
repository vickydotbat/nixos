# Users

This directory holds repository-level user doctrine.

Hosts choose from these declarations. The user tree names the person or account
role, the groups it needs, the password secret it expects, and whether Home
Manager should be forged for it. System modules consume the chosen accounts;
Home Manager modules consume the chosen user's home profile.

## Layout

- `admin/` is the mandatory repair account. It belongs to `wheel` and exists so
  a host has a known administrative handhold even when daily-driver users are
  being recalibrated. Its Home Manager profile is intentionally minimal: SSH key
  restoration plus Git stewardship for committing repairs in `/nix/nixos`.
  Home persistence is disabled for this account; it is a recovery grip, not a
  second daily home.
- `guest/` is an opt-in low-access account. It should not receive SSH private
  key material, administrative groups, or a Home Manager persistence profile.
- `vicky/` is the current daily-driver user, including her Home Manager profile
  and SSH client settings.

## Enabling the Guest Account

The guest account exists in the user registry, but no host receives it until the
host selects it. For `solanine`, add `guest` to `selectedUsers` in `flake.nix`:

```nix
selectedUsers = {
  inherit (userRegistry) admin guest vicky;
};
```

Then run the usual NixOS test activation before switching. The account has no
password secret, no SSH profile, no Home Manager profile, and no supplementary
groups by default. Those absences are part of the boundary; widen them only when
the host names the workflow and accepts the failure mode.

## Home Persistence Boundary

Home persistence is opt-in through an enabled Home Manager profile and
`theorem.home.base.persistence.enable`. The system persistence module may still
prepare `/nix/persist/home/<user>` for a selected Home Manager user so files have
a known place to be born during later repairs, but nothing from that home is
bound into persistent storage unless the user's Home profile declares
`home.persistence` entries.

On `solanine`, `admin` keeps Home Manager only for repair tools and explicitly
sets `theorem.home.base.persistence.enable = false`. `guest` has
`home.enable = false`, so it receives no Home Manager persistence surface at all.
If either account becomes a real working account later, name the workflow first
and add only the persistence paths that can survive rollback without becoming
hidden state.

## Home Profile Doctrine

The user profile is where personal Home Manager choices belong: terminal font
scale, clipboard trust, multiplexer key ownership, desktop layout, editor
workflow, language stacks, application autostart, and theme or prompt posture.
Reusable modules under `modules/home/` should expose those as options or carry
small repair-minded defaults. If a setting is only true for one operator and
Home Manager already exposes it directly, set that native option in the user's
profile. Theorem options are for coordinated mechanisms, not renamed copies of
package settings.

For users with Home Manager enabled, keep identity separate from profile
selection. Vicky's Home module entry point is `users/vicky/home.nix`; it imports
`identity.nix` for `home.username`, `home.homeDirectory`, `home.stateVersion`,
and Home Manager's own enablement, then imports `profiles.nix` for selected
`theorem.home.*` mechanisms and deliberate personal overrides.

Do not change `home.stateVersion` as an ordinary upgrade habit. It preserves
Home Manager compatibility for the account's existing state. Raising it is a
migration, not housekeeping; name the changed behavior and keep rollback visible
before turning that key.

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

## Application Access Groups

`nixcfg` is also the default boundary for local application access groups that
make installed desktop or operator tools usable. If an enabled module creates or
requires a group such as `networkmanager`, `video`, `scanner`, `docker`, or a
similar service-facing access group, the module should grant that group to the
selected users that already belong to `nixcfg`.

This is deliberate. Users trusted to maintain the system theorem should be able
to operate the applications and services that theorem installs, and the repair
account must not be left without the groups needed to diagnose or restore the
host. `admin` should receive every required usability group unless a module has
a documented reason to keep even the repair account away from that surface.

Do not expand these groups to `guest` or other outside accounts by default. A
non-steward account may receive an application access group only when the host
names the workflow and accepts the failure mode. Some groups are broad authority,
not decoration: `networkmanager` can change network and VPN state, container
groups can expose root-equivalent control paths, and hardware groups may expose
screens, cameras, disks, or attached devices. Give those keys to the hands that
are meant to carry them.

Static user declarations should carry durable identity facts and permanent
account doctrine: UID, home directory, administrative posture, repository
stewardship, and selected Home Manager profile. Service modules should own the
groups that become necessary only because that service or application is
enabled. When the service is disabled, the access should disappear with it.

## SSH Key Doctrine

Use Ed25519 keys for normal user SSH identities unless a specific legacy host
requires another algorithm:

```bash
ssh-keygen -t ed25519 -a 32 -f ~/.ssh/id_ed25519
```

The reusable Home Manager SSH module restores `id_ed25519` and
`id_ed25519.pub` from SOPS-backed secrets for outbound SSH, Git remotes, and
Git signing. This user identity mechanism is independent of whether the host
runs the system OpenSSH server. The system SSH module owns inbound `sshd`,
host keys, firewall exposure, and remote-login posture.

When `theorem.home.shell.git.enable` and `theorem.home.base.ssh.enable` are both
selected, the shared Git module signs commits with `~/.ssh/id_ed25519` by
default. User Git files should still own personal identity such as name and
email. Keep agent ownership singular per user profile. This repository uses the
OpenSSH agent through `programs.ssh.startAgent`; do not also enable a competing
`gpg-agent` SSH socket unless the user profile is deliberately moved to that
model.

## Failure Modes

- Do not put host hardware, host package choices, or machine-specific secrets
  here. Users describe accounts; hosts decide whether those accounts belong on a
  given machine.
- Do not give a daily-driver account duties that belong to `admin`. Repair needs
  a separate grip when personal configuration is the broken mechanism.
- `admin` owns UID 1000 by doctrine. Daily-driver accounts must use later fixed
  UIDs, and existing persisted files must be migrated by numeric owner before
  activating a host that changes an established user's UID.
