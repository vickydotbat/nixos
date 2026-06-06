# Modules

This directory contains reusable NixOS and Home Manager mechanisms.

[`docs/philosophy.md`](../docs/philosophy.md) is the boundary law for this tree.
If a module needs personal taste, host facts, hidden state, or broad implicit
behavior to make sense, change the module boundary before adding more options.

The module trees are imported recursively through `import-tree`, so every `.nix`
file here is part of the evaluated configuration. This is convenient, and
therefore sharp: files should expose options and remain quiet until a host or
user profile enables them.

## What It Controls

- `modules/nixos/` declares reusable system theorems under `theorem.nixos.*`
- `modules/home/` declares reusable Home Manager theorems under `theorem.home.*`
- category directories group mechanisms by maintenance concern

## How To Add A Module

Create a focused module in the appropriate tree. Prefer this pattern:

```nix
{
  config,
  lib,
  ...
}:

let
  cfg = config.theorem.nixos.category.name;
in
{
  options.theorem.nixos.category.name.enable = lib.mkEnableOption "short description";

  config = lib.mkIf cfg.enable {
    # mechanism goes here
  };
}
```

For Home Manager modules, use `theorem.home.category.name` instead.

Enable the module from the relevant profile file after adding it:

- NixOS: `hosts/<host>/profiles.nix`
- Home Manager: `users/<user>/profiles.nix`

Home Manager modules should carry their own reusable defaults. Do not make a
module a thin import of `users/<user>/` or another user-owned tree. The
user tree is for selection and calibration; the module tree is the forge where
the shared mechanism belongs.

System modules follow the same law. `modules/nixos/` should expose boot,
networking, desktop, security, persistence, and service mechanisms with named
options when those options describe a real grouped posture. `hosts/<host>/`
should use native NixOS options directly for one-to-one settings such as
firewall exposure, boot generation limits, or graphics library toggles. A final
system should build because the host and user profiles selected a shape, not
because a reusable module quietly guessed which machine or operator it was
serving.

User-facing Home modules may include repair-minded defaults, but personal
habits belong in `users/<user>/profiles.nix`: terminal font scale, clipboard
trust, shell prompt posture, editor workflow, desktop layout, autostart choices,
language stacks, and application preferences. If a value is already a direct
Home Manager option, set that native option instead of wrapping it in a theorem
option. Add theorem options only when they coordinate several settings or name a
maintenance boundary.

When a mechanism is only useful as another mechanism's substrate, prefer a
derived default over another profile switch. Examples: fonts and XDG support
following graphical applications, Home persistence following system
persistence, graphics/audio following a chosen desktop or gaming profile, and
sandbox support following a sandboxed application. Keep these defaults
overrideable with normal option assignment.

Nested defaults must be leaf defaults. If a module supplies defaults under an
attrset that profiles may also edit, use `lib.mkMerge` and put `lib.mkDefault`
on the child values. Do not set `some.attr = lib.mkDefault { ... };` for a
shared mechanism unless replacing the entire subtree is the intended repair
boundary. Whole-subtree defaults are easy to lose when a user profile adds one
personal setting beside them.

Do not derive optional applications, games, backup jobs, hardware conveniences,
or compatibility layers just because their substrate is present. Those remain
profile choices. Steam can provide the library and persistence substrate; it
must not silently imply a particular Steam game. Firefox can provide browser
state; it must not silently imply an encrypted backup ritual without the user
choosing that protection.

## Access Groups

When a module enables an application or service that is only usable through a
local access group, the module should grant that group to selected `nixcfg`
users by default. This keeps service-specific authority with the service
mechanism instead of freezing it into static user declarations.

Use this rule for groups that open ordinary operation of installed tools:
NetworkManager control, scanner or media device access, container engine
compatibility, virtualization consoles, and similar application-facing
surfaces. `admin` belongs to `nixcfg` by doctrine and should receive these
groups too; a repair account without access to the installed mechanism is a
locked toolbox.

Do not grant these groups to `guest` or outside accounts unless a host names a
specific workflow and accepts the risk. Some groups can change network state,
reach private devices, or become close to root-equivalent. The default rite is:
installed mechanism grants access to repository stewards; broader access needs
an explicit host decision.

## Package Review

Package-bearing modules should make the need visible at the same boundary that
installs the package. A system package belongs in `environment.systemPackages`
only when the mechanism is system-wide or needs root-owned integration. A user
package belongs in `home.packages` when the tool is part of one user's working
surface. Local recipes belong under `pkgs/`, then modules or profiles decide
whether to install them.

Before adding packages, run the package inventory rite in
[`docs/package-inventory.md`](../docs/package-inventory.md). Security-sensitive
packages deserve an explicit note in the module: secret tooling, SUID or
capability-bearing tools, browsers, container substrates, scanners, daemons, and
anything that opens a firewall port should state the failure mode it protects
against and the workflow it may break.

## Failure Modes

- A module without an enable option runs as soon as `import-tree` sees it.
- A module with an enable option but no profile entry may evaluate correctly while doing nothing.
- Aggregator files such as broad `default.nix` imports can duplicate recursive imports. Avoid them in these trees.
- Verify NixOS and Home Manager options before relying on them. Guesswork is a poor substitute for repair.

## Maintenance Reminders

Keep modules small enough that their failure modes are visible. If a mechanism starts controlling unrelated services, split it before the next maintainer has to learn it by pain.
