# Packages

This directory contains local package derivations and package-facing assets.

The boundary is deliberate: package files should build things. User configuration should install those things. Blurring that line makes later repair harder than it needs to be.

## What It Controls

- local derivations exposed through `pkgs/packages.nix`
- the default overlay exposed by `flake.nix`
- GIMP plugin assets consumed by the custom GIMP package
- Neverwinter and creative-tooling package recipes

## How To Add A Package

Add a focused derivation file, then expose it from `pkgs/packages.nix`:

```nix
{ pkgs }:

{
  example = pkgs.callPackage ./example.nix { };
}
```

Install the package from a NixOS or Home Manager module. Do not turn package derivations into Home Manager modules.

## Failure Modes

- Files not exposed from `pkgs/packages.nix` will not appear in the overlay or flake packages.
- Assets used by flakes must be tracked by Git before they can be seen during evaluation.
- Unfree or binary packages may need explicit license and source calibration.

## Maintenance Reminders

Keep package recipes boring where possible. A derivation that states its source, dependencies, install phase, and known caveats plainly is easier to resurrect after upstream changes.
