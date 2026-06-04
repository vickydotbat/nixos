# Boundary Repair Refactor Design

## Purpose

Repair the repository shape so the checked-in NixOS theorem follows
[`docs/philosophy.md`](../../philosophy.md) more closely without turning this
pass into a feature campaign.

The refactor is concerned with boundaries: which files own host facts, reusable
system mechanisms, reusable Home Manager mechanisms, user working surfaces,
local packages, documentation, and authority. Behavior should remain equivalent
unless the current behavior itself violates the repository doctrine.

## Scope

This pass prioritizes repair over feature completion.

In scope:

- Split oversized user profile surfaces into smaller user-owned files.
- Split reusable modules only where a file hides more than one mechanism or
  mixes reusable defaults with personal posture.
- Keep host selections explicit in `hosts/<host>/`.
- Keep root-owned mechanisms under `modules/nixos/` and Home Manager
  mechanisms under `modules/home/`.
- Keep personal workflow calibration under `users/<user>/`.
- Keep service-specific authority with the module that creates or requires it.
- Promote any repaired doctrine from `docs/TODO.md` into the module, profile,
  README, or focused document future maintainers will read first.
- Verify with targeted Nix evaluation, formatting, `nix flake check`, and a
  dry build where the local execution context permits it.

Out of scope:

- Adding new hardening features.
- Migrating to `flake-parts`.
- Renaming the repository stewardship group.
- Designing personal Home flakes outside this system flake.
- Introducing a new package update strategy for fast-moving inputs.
- Changing disk layout, secure boot, LUKS, or Btrfs rollback behavior.

## Current Pressure Points

The repository already has the expected lanes:

- `hosts/<host>/` owns host identity, hardware, storage, secrets wiring, and
  profile selection.
- `modules/nixos/` owns reusable root-controlled mechanisms under
  `theorem.nixos.*`.
- `modules/home/` owns reusable Home Manager mechanisms under
  `theorem.home.*`.
- `users/<user>/` owns account doctrine and selected user working surfaces.
- `pkgs/` owns local package recipes.
- `docs/` owns maintenance doctrine and repair ledgers.

The repair need is not a wholesale reshaping. The visible strain is
concentration:

- `users/vicky/profiles.nix` carries too much daily-driver surface in one file.
- `modules/home/desktop/plasma.nix`, `modules/home/shell/shell.nix`,
  `modules/home/web/firefox.nix`, and `modules/home/shell/codex.nix` are large
  enough that their internal boundaries need review.
- `modules/nixos/security/hardening.nix` may contain separable security
  mechanisms that should be easier to audit independently.
- Authority surfaces such as selected Home imports, Nix trusted users, service
  access groups, SOPS bindings, and elevation profiles must stay visibly owned
  by the mechanisms that grant them.

## Design

### User Profile Split

Split `users/vicky/profiles.nix` into focused files below `users/vicky/`, then
make `profiles.nix` an import coordinator.

The expected files are deliberately user-owned:

- `users/vicky/profiles/base.nix` for broad Home substrate selections.
- `users/vicky/profiles/desktop.nix` for personal desktop applications and
  autostart choices.
- `users/vicky/profiles/editor.nix` for editor posture, extensions, and
  language tooling.
- `users/vicky/profiles/shell.nix` for shell, terminal, Git, and Codex posture.
- `users/vicky/profiles/web.nix` for browser choices and browser policy.
- `users/vicky/profiles/gaming.nix` for game tooling and related user state.

This split should not move Vicky-specific preferences into reusable modules.
Themes, shortcuts, editor behavior, browser preference details, Spicetify
extensions, Discord autostart, and daily-driver package choices remain personal
profile content.

### Reusable Home Modules

Inspect each large Home module before splitting it. Split only when there is a
real mechanism boundary.

Acceptable split examples:

- Firefox package/profile substrate separated from search, policy, or preference
  sets when those sets can be reasoned about independently.
- Shell baseline separated from NixOS repair aliases when standalone Home
  evaluation should stay plain.
- Codex package/wrapper support separated from persistence and CLI config when
  those surfaces have different failure modes.
- Plasma reusable substrate separated from personal layout if personal layout is
  still present in the reusable module.

Do not split merely to reduce line count. A split that forces maintainers to
open more files for one mechanism is not repair.

### System Authority Audit

Audit root-controlled modules for ownership clarity:

- `lib/mkSystem.nix` remains the explicit trust gate for system-managed Home
  imports.
- `modules/nixos/base/nix-trusted-users.nix` should continue deriving trusted
  users from repository stewardship rather than arbitrary local users.
- Service access groups should remain with the service module that requires
  them.
- SOPS runtime secret bindings should remain host-declared and should not place
  plaintext material in the Nix store.
- `run0-sudo` should remain a separate selected profile until activation and
  recovery are tested.

If `modules/nixos/security/hardening.nix` contains separable mechanisms with
distinct risks or validation rites, extract them into sibling modules under
`modules/nixos/security/` while preserving the existing option surface or adding
compatibility aliases where needed.

### Documentation Repair

Update documentation only where the refactor changes the reader's path:

- `users/README.md` if the user profile split changes how maintainers navigate
  user doctrine.
- `modules/home/README.md` if Home module boundaries change.
- `modules/nixos/README.md` if system authority boundaries change.
- `docs/TODO.md` only to mark repaired items and point to the new mechanism
  home.

Documentation should use the repository voice: technically direct, clear about
failure modes, and spare with metaphor.

## Validation

Run the smallest useful checks after each repair slice:

```bash
nixfmt --check <changed-nix-files>
```

Run broader checks before claiming the pass is repaired:

```bash
nix eval .#nixosConfigurations.solanine.config.system.name
nix eval .#nixosConfigurations.solanine.config.home-manager.users --apply builtins.attrNames
nix flake check
nixos-rebuild dry-build --flake .#solanine
```

If the sandbox or host context blocks a command, record the exact failure and do
not count the blocked command as completed verification.

## Success Criteria

- No reusable module imports Vicky's private working surface.
- Vicky's Home profile is split into reviewable user-owned files.
- Reusable modules remain quiet until selected or until serving a documented
  derived substrate.
- Authority surfaces are owned by the modules that grant them.
- Documentation points future maintainers to the repaired boundaries.
- Formatting and Nix evaluation checks pass or have a concrete, reported
  environment blocker.
