# Import Tree Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the NixOS configuration to `import-tree` composition and add host-controlled option-style profile enablers.

**Architecture:** `flake.nix` imports full module trees with `import-tree`. Reusable NixOS modules expose `vicky.*.enable` options, while `hosts/solanine/profiles.nix` enables the behavior for this host.

**Tech Stack:** Nix flakes, NixOS modules, Home Manager modules, `github:vic/import-tree`.

---

### Task 1: Wire import-tree

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] Add `import-tree.url = "github:vic/import-tree"`.
- [ ] Include `import-tree` in flake outputs.
- [ ] Replace explicit host, NixOS module, and Home Manager import lists with import-tree calls.

### Task 2: Rename tree aggregators

**Files:**
- Move: `hosts/solanine/default.nix` to `hosts/solanine/system.nix`
- Move: `home/users/vicky/default.nix` to `home/users/vicky/identity.nix`

- [ ] Rename files that were manual aggregators so importing every `.nix` file recursively does not duplicate imports.
- [ ] Keep host identity and Home Manager identity as normal modules in the tree.

### Task 3: Add NixOS enablers

**Files:**
- Modify: `modules/nixos/**/*.nix`
- Create: `hosts/solanine/profiles.nix`

- [ ] Wrap reusable NixOS module config behind `vicky.*.enable` options.
- [ ] Enable the same set of modules for `solanine` in `hosts/solanine/profiles.nix`.

### Task 4: Validate

**Files:**
- All changed Nix files

- [ ] Run `nix fmt`.
- [ ] Run `nix flake check`.
- [ ] Run `nix build .#nixosConfigurations.solanine.config.system.build.toplevel --dry-run`.
