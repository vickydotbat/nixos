# OpenCode Home Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable Home Manager module under `modules/home/agents/` that installs OpenCode, persists its configuration directory when Home persistence is enabled, and keeps all user-specific activation and configuration in user profiles.

**Architecture:** Follow the existing `theorem.home.agents.*` shape used by `headroom.nix`, `odysseus.nix`, and `ollama.nix`. The module declares a small option surface, installs `pkgs.opencode` when enabled, and binds persistence to `theorem.home.base.persistence.enable`. Vicky's agent profile enables the module; the shared module does not auto-enable or inject personal settings.

**Tech Stack:** NixOS flakes, Home Manager, `import-tree`, `nixfmt`, `nix eval`, `nix flake check`, `nixos-rebuild dry-build`.

## Global Constraints

- Assume `pkgs.opencode` in nixpkgs is the requested "Open Code" tool (MIT, terminal AI coding agent). If a different package is intended, replace the package default before implementation.
- The module lives under `theorem.home.agents.opencode`.
- User-specific activation and configuration belong in `users/<user>/profiles/agents.nix`, not in the shared module.
- Persistence must gate on both `options.home ? persistence` and `config.theorem.home.base.persistence.enable`.
- Do not seed, write, or assume OpenCode runtime configuration in the shared module.
- Do not run services, activation hooks, or long-running processes from Home Manager.
- Format all touched `.nix` files with `nixfmt`.
- Verify with `nix eval` and `nix flake check` before claiming the work passes.

## Task 1: Create The Shared `opencode` Home Module

**Files:**
- Create: `modules/home/agents/opencode.nix`

**Interfaces:**
- Consumes: `config.theorem.home.base.persistence.enable`, `options.home ? persistence`, `pkgs.opencode`
- Produces: `options.theorem.home.agents.opencode.{enable, package, persist}` and the matching `config` block

- [ ] **Step 1: Write the module file**

Create `modules/home/agents/opencode.nix`:

```nix
{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.opencode;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
in
{
  options.theorem.home.agents.opencode = {
    enable = lib.mkEnableOption "OpenCode terminal AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.opencode;
      description = "OpenCode package to install.";
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist OpenCode configuration under `~/.config/opencode` when Home
        persistence is active. Disable this on hosts where the agent should
        begin with a blank configuration after each reboot.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
        directories = [
          ".config/opencode"
        ];
      };
    })
  ];
}
```

- [ ] **Step 2: Format the new module**

Run:

```bash
nixfmt modules/home/agents/opencode.nix
```

Expected: exits 0 with no remaining formatting differences.

- [ ] **Step 3: Verify the module evaluates without selecting it**

Run:

```bash
nix eval .#homeModules.shared.options.theorem.home.agents.opencode.enable.description
```

Expected: evaluation succeeds and returns the `mkEnableOption` description string.

- [ ] **Step 4: Commit the shared module**

```bash
git add modules/home/agents/opencode.nix
git commit -m "feat(home): add reusable opencode agent module"
```

## Task 2: Activate The Module From Vicky's Agent Profile

**Files:**
- Modify: `users/vicky/profiles/agents.nix`

**Interfaces:**
- Consumes: `theorem.home.agents.opencode` from Task 1
- Produces: a user profile that enables the agent for Vicky

- [ ] **Step 1: Add the OpenCode selection**

Modify `users/vicky/profiles/agents.nix` to enable the module:

```nix
{
  theorem.home.agents = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "0.0.0.0";
    };
    odysseus = {
      enable = true;
    };
    headroom = {
      enable = true;
    };
    opencode = {
      enable = true;
    };
  };
}
```

- [ ] **Step 2: Format the profile**

Run:

```bash
nixfmt users/vicky/profiles/agents.nix
```

Expected: exits 0.

- [ ] **Step 3: Verify the option is enabled for the user**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.theorem.home.agents.opencode.enable
```

Expected: returns `true`.

- [ ] **Step 4: Verify the package appears in the user environment**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.home.packages --apply 'pkgs: builtins.any (p: p.pname == "opencode") pkgs'
```

Expected: returns `true`.

- [ ] **Step 5: Commit the profile change**

```bash
git add users/vicky/profiles/agents.nix
git commit -m "feat(users/vicky): enable opencode agent"
```

## Task 3: Verify Persistence Wiring

**Files:**
- Read: `modules/home/base/persistence.nix`
- Read: `modules/home/agents/opencode.nix`

- [ ] **Step 1: Verify the persistence directory is declared when persistence is active**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.home.persistence.\"/nix/persist\".directories --apply 'dirs: builtins.any (d: d == ".config/opencode") dirs'
```

Expected: returns `true` on a host where `theorem.home.base.persistence.enable` is true.

- [ ] **Step 2: Confirm the module remains quiet when disabled**

Run a synthetic check with a profile that disables the module:

```bash
nix eval --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    hm = flake.homeModules.shared;
    cfg = (import flake.inputs.home-manager { }).lib.homeManagerConfiguration {
      pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [ hm { theorem.home.agents.opencode.enable = false; } ];
    };
  in
  cfg.config.home.packages == []
'
```

Expected: returns `true`. If this command is awkward, replace it with a direct `nix eval` against a host configuration that does not select the user, or note the limitation.

## Task 4: Final Validation

**Files:**
- All touched files

- [ ] **Step 1: Check formatting of all changed files**

Run:

```bash
nixfmt --check modules/home/agents/opencode.nix users/vicky/profiles/agents.nix
```

Expected: exits 0.

- [ ] **Step 2: Run flake check**

Run:

```bash
nix flake check
```

Expected: exits 0. If it fails due to unrelated local state, record the exact failure and do not claim success.

- [ ] **Step 3: Run a dry build on the local NixOS host**

Run:

```bash
nixos-rebuild dry-build --flake .#solanine
```

Expected: exits 0 on the NixOS host with a usable Nix daemon. If this command cannot run in the current crucible, record the reason and stop before `switch`.

- [ ] **Step 4: Review the diff**

Run:

```bash
git diff --stat
```

Expected: only `modules/home/agents/opencode.nix` and `users/vicky/profiles/agents.nix` are changed.

---

## Open Question Before Execution

The plan assumes the requested "Open Code" tool is the `opencode` package already in nixpkgs (`pkgs.opencode`, MIT, terminal AI coding agent). If a different project was intended, stop after Task 1 and swap the package default before enabling it in the user profile.
