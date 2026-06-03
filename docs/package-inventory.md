# Package Inventory Review

This is the hardening review rite for package growth. It does not try to
freeze the installed closure; Nix already carries that exact theorem. This file
names the entry points where packages are allowed to enter the system, the
commands that expose the current inventory, and the review questions that keep
the host from collecting unexamined tools.

## Evaluation Commands

Run these from the repository root before approving a package-bearing change:

```bash
mkdir -p .cache
XDG_CACHE_HOME=$PWD/.cache nix eval --json \
  .#nixosConfigurations.solanine.config.environment.systemPackages \
  --apply 'pkgs: map (p: p.pname or p.name) pkgs'

XDG_CACHE_HOME=$PWD/.cache nix eval --json \
  .#nixosConfigurations.solanine.config.home-manager.users \
  --apply 'users: builtins.mapAttrs (_: cfg: map (p: p.pname or p.name) cfg.home.packages) users'

XDG_CACHE_HOME=$PWD/.cache nix eval --json \
  .#nixosConfigurations.solanine.config.theorem.nixos.base.nix.unfreePackageNames

XDG_CACHE_HOME=$PWD/.cache nix eval \
  .#nixosConfigurations.solanine.config.nixpkgs.config.allowUnfree

XDG_CACHE_HOME=$PWD/.cache nix eval --impure --json --expr '
  let
    flake = builtins.getFlake (builtins.toString ./.);
    cfg = flake.nixosConfigurations.solanine.config;
    pkgs = flake.nixosConfigurations.solanine.pkgs;
  in {
    discord = cfg.nixpkgs.config.allowUnfreePredicate pkgs.discord;
    hello = cfg.nixpkgs.config.allowUnfreePredicate pkgs.hello;
  }'
```

Use the workspace-local cache when a sandbox or hardened account cannot write
to the user's normal Nix fetcher cache. The Home package inventory is keyed by
selected Home Manager user, so minimal repair accounts such as `admin` are
reviewed beside full daily-driver profiles such as `vicky`. The output should
be compared against the changed module or profile. A package that appears
without a corresponding mechanism is a warning light. For unfree packages, the
global switch should evaluate to `false`; named proprietary tools should pass
the predicate only when their exact package names are present in
`theorem.nixos.base.nix.unfreePackageNames`.

For rebuild confidence, follow the inventory with:

```bash
XDG_CACHE_HOME=$PWD/.cache nix flake check
XDG_CACHE_HOME=$PWD/.cache nixos-rebuild dry-build --flake .#solanine
```

The dry build belongs on the NixOS host or on a deployer that can talk to the
Nix daemon. In restricted sandboxes, record the daemon failure rather than
pretending the rite was completed.

## Package Entry Points

| Entry Point | Current Purpose | Review Boundary |
|---|---|---|
| `modules/nixos/base/packages.nix` | Small rescue set: `git`, editors, archive tools. | Only tools expected on every maintained host belong here. |
| `hosts/solanine/profiles.nix` | Host-local disk, filesystem, archive, and compatibility tools. | Keep hardware and workflow packages host-specific unless several hosts prove the need. |
| `modules/nixos/security/diagnostics.nix` | Manual hardening diagnostics: Lynis, AIDE, ClamAV, SBOM and vulnerability scan tools when selected. | Tools are not daemons by default; scheduling and persistence need separate modules. |
| `modules/nixos/security/sops.nix` | Secret maintenance tooling: `sops`, `age`, and `mkpasswd`. | These tools serve protected state; do not broaden them into a general security grab bag. |
| `modules/nixos/security/firejail.nix` and `modules/nixos/desktop/jailwolf.nix` | Firejail substrate and a disposable LibreWolf launcher. | Firejail is useful confinement and a SUID surface. Wrap named applications only. |
| `modules/nixos/security/run0.nix` | Installs the systemd package when the `run0` elevation profile is selected. | Do not make this the default elevation path until recovery and admin rules are tested. |
| `modules/nixos/gaming/steam.nix` | Steam, Steam hardware support, and `steam-run`. | Unfree package predicates and firewall openings must remain explicit. |
| `modules/nixos/desktop/graphics.nix` | Graphics support and `vulkan-tools` for graphical or gaming profiles. | Graphics follows a declared graphical need; optional applications do not follow it. |
| `modules/home/**` | User package mechanisms such as browsers, fonts, editors, Blender, GIMP, Neverwinter tooling, and backup helpers. | Shared Home modules carry reusable mechanisms; personal package stacks stay in `users/<user>/profiles.nix`. |
| `pkgs/packages.nix` | Local package derivations and overlay exports. | Package recipes build artifacts; NixOS and Home Manager modules decide whether to install them. |

## Local Nixpkgs And Overlay Work

Local nixpkgs work is a repair tool, not a permanent hiding place. When a
package needs a local patch, override, or new derivation, keep the path
visible:

- A temporary local nixpkgs checkout or worktree should be named in the review
  note, and the final diff should prove the flake no longer depends on an
  unreviewed local path unless that is the explicit purpose of the change.
- An overlay should explain why it needs to alter the package set instead of
  adding a narrow local derivation under `pkgs/`. Use overlays for package-set
  relationships; use `callPackage` for ordinary local recipes.
- Package definitions should keep source selection, lockfiles, wrappers,
  runtime dependencies, metadata, and tests visible. Rust packages should use a
  committed `Cargo.lock` where practical. Wrapped binaries should name the tools
  injected into `PATH`.
- Debugging a package or module should leave behind the smallest useful rite:
  the `nix build`, `nix eval`, `nix why-depends`, or `nix repl` expression that
  exposed the problem.

## Review Questions

Before adding a package, answer these in the module, profile, or review note:

- Which mechanism needs this package, and what fails without it?
- Should it be system-wide, user-local, or only a local derivation exposed by
  the overlay?
- Is it security-sensitive, unfree, network-facing, SUID/capability-bearing, or
  a daemon in disguise?
- Does it require persistence, secrets, firewall exposure, hardware access, or
  a recovery path?
- Is the package already available through a narrower module option or profile
  selection?
- Does this need an overlay, or would a normal `pkgs.callPackage` derivation be
  easier to audit?
- If a local nixpkgs checkout was used, has the final flake input been restored
  or deliberately pinned?

## Failure Modes

- A broad `environment.systemPackages` addition can become a permanent host
  habit without any module owning the reason.
- A Home Manager package placed in a reusable module can leak one operator's
  workflow into future users.
- A local derivation installed directly from a user file hides the package
  boundary; expose it through `pkgs/packages.nix`, then install it from a module
  or profile.
- Unfree packages must remain visible through
  `theorem.nixos.base.nix.unfreePackageNames`; a global `allowUnfree = true`
  defeats the repository's audit posture.
- Diagnostic tools can become noisy daemons if scheduling, databases, and
  persistence are added without a separate rite.
- A local nixpkgs path can make the host depend on a developer checkout that is
  not available during reinstall, remote deploy, or another operator's review.
