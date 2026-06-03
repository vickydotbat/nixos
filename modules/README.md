# Modules

This directory contains reusable NixOS and Home Manager mechanisms.

The module trees are imported recursively through `import-tree`, so every `.nix` file here is part of the evaluated configuration. This is convenient, and therefore sharp: files should expose options and remain quiet until a host or user profile enables them.

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

When a mechanism is only useful as another mechanism's substrate, prefer a
derived default over another profile switch. Examples: fonts and XDG support
following graphical applications, Home persistence following system
persistence, graphics/audio following a chosen desktop or gaming profile, and
sandbox support following a sandboxed application. Keep these defaults
overrideable with normal option assignment.

Do not derive optional applications, games, backup jobs, hardware conveniences,
or compatibility layers just because their substrate is present. Those remain
profile choices. Steam can provide the library and persistence substrate; it
must not silently imply a particular Steam game. Firefox can provide browser
state; it must not silently imply an encrypted backup ritual without the user
choosing that protection.

## Failure Modes

- A module without an enable option runs as soon as `import-tree` sees it.
- A module with an enable option but no profile entry may evaluate correctly while doing nothing.
- Aggregator files such as broad `default.nix` imports can duplicate recursive imports. Avoid them in these trees.
- Verify NixOS and Home Manager options before relying on them. Guesswork is a poor substitute for repair.

## Maintenance Reminders

Keep modules small enough that their failure modes are visible. If a mechanism starts controlling unrelated services, split it before the next maintainer has to learn it by pain.
