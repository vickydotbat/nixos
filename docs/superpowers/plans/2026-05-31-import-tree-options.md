# Import Tree Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task by task. Keep the checkbox syntax intact; it is the ledger by which the repair is measured.

## Purpose

Convert the NixOS configuration to `import-tree` composition and add host-controlled option-style profile enablers.

The point of this theorem is to reduce import drift. Modules should be discoverable by tree position, while host profiles remain explicit about which mechanisms are enabled.

## Architecture

`flake.nix` imports full module trees with `import-tree`. Reusable NixOS modules expose `theorem.nixos.*.enable` options, while `hosts/solanine/profiles.nix` enables the behavior for this host.

## Tech Stack

Nix flakes, NixOS modules, Home Manager modules, `github:vic/import-tree`.

## Failure Modes

- Recursive imports can duplicate old aggregator files if the tree is not renamed carefully.
- Option-style enablers can hide behavior if `solanine` does not explicitly enable the same mechanisms it used before.
- `flake.lock` churn is expected when adding `import-tree`; unrelated lock churn is not.

---

## Task 1: Wire import-tree

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] Add `import-tree.url = "github:vic/import-tree"`.
- [ ] Include `import-tree` in flake outputs.
- [ ] Replace explicit host, NixOS module, and Home Manager import lists with import-tree calls.

## Task 2: Rename tree aggregators

**Files:**
- Move: `hosts/solanine/default.nix` to `hosts/solanine/system.nix`
- Move: `home/users/vicky/default.nix` to `home/users/vicky/identity.nix`

- [ ] Rename files that were manual aggregators so importing every `.nix` file recursively does not duplicate imports.
- [ ] Keep host identity and Home Manager identity as normal modules in the tree.

## Task 3: Add NixOS enablers

**Files:**
- Modify: `modules/nixos/**/*.nix`
- Create: `hosts/solanine/profiles.nix`

- [ ] Wrap reusable NixOS module config behind `theorem.nixos.*.enable` options.
- [ ] Enable the same set of modules for `solanine` in `hosts/solanine/profiles.nix`.

## Task 4: Validate

**Files:**
- All changed Nix files

- [ ] Run `nix fmt`.
- [ ] Run `nix flake check`.
- [ ] Run `nix build .#nixosConfigurations.solanine.config.system.build.toplevel --dry-run`.
