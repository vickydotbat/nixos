# Boundary Repair Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair repository boundaries by splitting oversized user-owned profile state, auditing reusable module ownership, and updating documentation without adding new features.

**Architecture:** Keep the existing flake and `import-tree` architecture. Make `users/vicky/profiles.nix` a small import coordinator and move Vicky-specific Home Manager selections into focused files under `users/vicky/profiles/`. Reusable modules remain under `modules/home/` and `modules/nixos/`; edit them only when inspection proves a real boundary violation.

**Tech Stack:** Nix flakes, NixOS modules, Home Manager modules, `nixfmt`, targeted `nix eval`, `nix flake check`, `nixos-rebuild dry-build`.

---

### Task 1: Baseline Evaluation Snapshot

**Files:**
- Read: `users/vicky/profiles.nix`
- Read: `modules/home/**/*.nix`
- Read: `modules/nixos/**/*.nix`
- No source edits

- [ ] **Step 1: Capture selected Home Manager users**

Run:

```bash
nix eval .#nixosConfigurations.solanine.config.home-manager.users --apply builtins.attrNames
```

Expected: evaluation succeeds and lists selected Home Manager users, currently including `admin` and `vicky`.

- [ ] **Step 2: Capture Vicky theorem option subtree**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.theorem.home --apply 'home: { categories = builtins.attrNames home; base = builtins.attrNames home.base; desktop = builtins.attrNames home.desktop; editor = builtins.attrNames home.editor; gaming = builtins.attrNames home.gaming; shell = builtins.attrNames home.shell; web = builtins.attrNames home.web; }'
```

Expected: evaluation succeeds and prints serializable category keys for the selected `theorem.home.*` options.

- [ ] **Step 3: Capture authority-sensitive system values**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.nix.settings.trusted-users
nix eval --json .#nixosConfigurations.solanine.config.users.users.admin.extraGroups
nix eval --json .#nixosConfigurations.solanine.config.users.users.vicky.extraGroups
nix eval --json .#nixosConfigurations.solanine.config.sops.secrets --apply builtins.attrNames
```

Expected: each command evaluates. The output becomes the local comparison point after the refactor.

### Task 2: Split Vicky Profile By Ownership Surface

**Files:**
- Modify: `users/vicky/profiles.nix`
- Create: `users/vicky/profiles/base.nix`
- Create: `users/vicky/profiles/desktop.nix`
- Create: `users/vicky/profiles/editor.nix`
- Create: `users/vicky/profiles/gaming.nix`
- Create: `users/vicky/profiles/shell.nix`
- Create: `users/vicky/profiles/web.nix`

- [ ] **Step 1: Replace the large profile with an import coordinator**

Write `users/vicky/profiles.nix` as:

```nix
{
  imports = [
    ./profiles/base.nix
    ./profiles/desktop.nix
    ./profiles/editor.nix
    ./profiles/gaming.nix
    ./profiles/shell.nix
    ./profiles/web.nix
  ];
}
```

- [ ] **Step 2: Move broad Home substrate selections**

Create `users/vicky/profiles/base.nix` with:

```nix
{
  theorem.home.base = {
    distrobox.enable = true;
    ssh.enable = true;
  };
}
```

- [ ] **Step 3: Move personal desktop applications**

Create `users/vicky/profiles/desktop.nix` by moving these exact parts from the original `users/vicky/profiles.nix`:

- function arguments needed by this slice: `inputs`, `pkgs`, and `...`
- lines 9-11 for `spicePkgs`
- lines 19-43 for `theorem.home.desktop`
- lines 436-443 for `programs.ghostty.settings`

The resulting file must keep `pkgs.gimp3-custom` and `inputs.spicetify-nix` in this user-owned profile slice.

- [ ] **Step 4: Move editor posture**

Create `users/vicky/profiles/editor.nix` by moving lines 45-352 from the original `users/vicky/profiles.nix`.

The resulting file needs function arguments `pkgs` and `...`, because the VS Code extension and tool lists use `pkgs.vscode-extensions` and `with pkgs`.

- [ ] **Step 5: Move gaming selection**

Create `users/vicky/profiles/gaming.nix` with:

```nix
{
  theorem.home.gaming.nwn.enable = true;
}
```

- [ ] **Step 6: Move shell, terminal, Git, and Codex posture**

Create `users/vicky/profiles/shell.nix` by moving lines 358-427 from the original `users/vicky/profiles.nix`.

The resulting file needs function arguments `config`, `repository`, and `...`, because the Codex settings refer to `repository.path` and `config.home.homeDirectory`.

- [ ] **Step 7: Move browser selections**

Create `users/vicky/profiles/web.nix` with:

```nix
{
  theorem.home.web = {
    firefox.enable = true;
    firefox-backup.enable = true;
    ungoogled-chromium.enable = true;
  };
}
```

- [ ] **Step 8: Format the split files**

Run:

```bash
nixfmt users/vicky/profiles.nix users/vicky/profiles/*.nix
```

Expected: command exits 0 and only formatting changes are applied.

- [ ] **Step 9: Verify the split preserves evaluation**

Run:

```bash
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.theorem.home --apply 'home: { categories = builtins.attrNames home; base = builtins.attrNames home.base; desktop = builtins.attrNames home.desktop; editor = builtins.attrNames home.editor; gaming = builtins.attrNames home.gaming; shell = builtins.attrNames home.shell; web = builtins.attrNames home.web; }'
```

Expected: evaluation succeeds and the category keys match the Task 1 baseline.

### Task 3: Document The Repaired User Profile Boundary

**Files:**
- Modify: `users/README.md`
- Modify: `docs/TODO.md`

- [ ] **Step 1: Update user navigation documentation**

Add a short note to `users/README.md` under "Home Profile Doctrine" explaining that `users/vicky/profiles.nix` is now an import coordinator and that focused files under `users/vicky/profiles/` own Vicky's personal editor, desktop, shell, web, and gaming posture.

- [ ] **Step 2: Retire the matching TODO progress item**

Edit `docs/TODO.md` in the "Home Module Boundary" section to record that Vicky's large user profile has been split into focused user-owned files. Keep unresolved items, such as reusable Plasma calibration, open.

- [ ] **Step 3: Format touched Markdown by inspection**

Read the changed Markdown sections:

```bash
sed -n '50,100p' users/README.md
sed -n '100,180p' docs/TODO.md
```

Expected: text is clear, line-wrapped, and points to the repaired mechanism home.

### Task 4: Audit Large Reusable Modules For Boundary Violations

**Files:**
- Read: `modules/home/desktop/plasma.nix`
- Read: `modules/home/shell/shell.nix`
- Read: `modules/home/web/firefox.nix`
- Read: `modules/home/shell/codex.nix`
- Read: `modules/nixos/security/hardening.nix`
- Modify only if a real boundary violation is found.

- [ ] **Step 1: Check reusable modules for user imports**

Run:

```bash
rg -n "users/vicky|/home/vicky|vicky|users/<user>|import .*users" modules/home modules/nixos
```

Expected: no reusable module imports Vicky's user profile or hard-codes her private Home path. Documentation examples are acceptable only if clearly generic.

- [ ] **Step 2: Check for modules that run without an option gate**

Run:

```bash
rg -L "options\\.theorem\\.|config = lib\\.mkIf|lib\\.mkIf cfg\\.enable|mkIf cfg\\.enable" modules/home/**/*.nix modules/nixos/**/*.nix
```

Expected: review any listed files manually. A file may be acceptable if it is a companion substrate with a documented derived default or if the search missed its gate.

- [ ] **Step 3: Inspect large modules manually**

Read the large modules and classify each one:

```bash
sed -n '1,220p' modules/home/desktop/plasma.nix
sed -n '1,220p' modules/home/shell/shell.nix
sed -n '1,220p' modules/home/web/firefox.nix
sed -n '1,220p' modules/home/shell/codex.nix
sed -n '1,220p' modules/nixos/security/hardening.nix
```

Expected: either identify a specific split with files and preserved options, or record that the module is large but still owns one coherent mechanism.

- [ ] **Step 4: Apply only proven splits**

If a split is required, create the smallest sibling module that preserves the public option surface. The split must move complete option or implementation blocks, keep the old option names valid, and run the targeted evaluation from Task 5 before any further refactor.

Expected: no option names are removed without compatibility handling.

### Task 5: Final Verification And Review

**Files:**
- All changed files

- [ ] **Step 1: Check formatting**

Run:

```bash
nixfmt --check users/vicky/profiles.nix users/vicky/profiles/*.nix
```

Expected: exits 0.

- [ ] **Step 2: Run targeted evaluation**

Run:

```bash
nix eval .#nixosConfigurations.solanine.config.system.name
nix eval .#nixosConfigurations.solanine.config.home-manager.users --apply builtins.attrNames
nix eval --json .#nixosConfigurations.solanine.config.home-manager.users.vicky.theorem.home --apply 'home: { categories = builtins.attrNames home; base = builtins.attrNames home.base; desktop = builtins.attrNames home.desktop; editor = builtins.attrNames home.editor; gaming = builtins.attrNames home.gaming; shell = builtins.attrNames home.shell; web = builtins.attrNames home.web; }'
```

Expected: each command exits 0.

- [ ] **Step 3: Run flake check**

Run:

```bash
nix flake check
```

Expected: exits 0, unless blocked by the local sandbox or daemon state. If blocked, record the exact failure.

- [ ] **Step 4: Run dry build**

Run:

```bash
nixos-rebuild dry-build --flake .#solanine
```

Expected: exits 0 on a NixOS host with a usable Nix daemon. If blocked, record the exact failure and do not claim the dry build passed.

- [ ] **Step 5: Review diff against the design**

Run:

```bash
git diff --stat
git diff -- users/vicky users/README.md docs/TODO.md modules/home modules/nixos
```

Expected: diff shows a boundary-preserving split and documentation repair, not feature additions.
