# Dendritic NixOS Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task by task. Keep the checkbox syntax intact; it is the ledger by which the repair is measured.

## Purpose

Reorganize the flat NixOS flake into host, NixOS module, Home Manager user, and package trees without intentionally changing behavior.

This is a repair pass, not a reinvention. The desired outcome is a clearer machine: host identity in one place, reusable mechanisms in another, and package derivations kept out of user configuration.

## Architecture

`flake.nix` remains the composition root. Host-specific config lives under `hosts/solanine`, reusable system concerns under `modules/nixos`, Vicky's Home Manager config under `home/users/vicky`, and `pkgs` contains package derivations only.

## Tech Stack

Nix flakes, NixOS modules, Home Manager modules.

## Failure Modes

- Relative imports can break when files move. Check each path instead of trusting memory.
- Refactors that accidentally change behavior are regressions, even when the new tree looks cleaner.
- Package derivations imported as Home Manager modules blur a boundary that future maintenance depends on.

---

## Task 1: Move Entrypoints

**Files:**
- Modify: `flake.nix`
- Create: `hosts/solanine/default.nix`
- Move: `hardware-configuration.nix` to `hosts/solanine/hardware-configuration.nix`
- Create: `home/users/vicky/default.nix`

- [ ] Move the current host and Home Manager entrypoints to their target directories.
- [ ] Update `flake.nix` imports to reference `hosts/solanine/default.nix` and `home/users/vicky/default.nix`.
- [ ] Keep imports valid after the new relative paths.

## Task 2: Split NixOS Concerns

**Files:**
- Create files under `modules/nixos/base`, `modules/nixos/desktop`, `modules/nixos/gaming`, and `modules/nixos/virtualisation`
- Modify: `hosts/solanine/default.nix`

- [ ] Extract boot, locale, Nix settings, users, SSH, packages, desktop, gaming, Podman, and `nix-ld` into focused NixOS modules.
- [ ] Keep host-specific hostname, hardware, and persistence in `hosts/solanine`.
- [ ] Import all extracted modules from `hosts/solanine/default.nix`.

## Task 3: Split Home Manager Concerns

**Files:**
- Create focused files under `home/users/vicky`
- Modify: `home/users/vicky/default.nix`

- [ ] Extract packages, Git, SSH, desktop apps, GIMP, Spicetify, and Neverwinter tooling into focused modules.
- [ ] Keep `home.username`, `home.homeDirectory`, `home.stateVersion`, and `programs.home-manager.enable` in the user default module.

## Task 4: Clean Package Boundary

**Files:**
- Create: `pkgs/default.nix`
- Modify: `pkgs/cleanmodels.nix`
- Modify: `pkgs/nwnexplorer.nix`
- Modify: `home/users/vicky/nwn.nix`

- [ ] Convert `pkgs/cleanmodels.nix` and `pkgs/nwnexplorer.nix` to package derivations.
- [ ] Expose local packages via `pkgs/default.nix`.
- [ ] Install local packages from Home Manager instead of importing package files as Home Manager modules.

## Task 5: Verify

**Files:**
- All changed Nix files

- [ ] Run `nixfmt` or the available formatter if present.
- [ ] Run `nix flake check`.
- [ ] If `flake check` is too broad or fails for unrelated reasons, run a direct local build command for `.#nixosConfigurations.solanine.config.system.build.toplevel`.
