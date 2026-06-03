# Hosts

This directory holds host identity and host-specific state.

The reusable mechanisms live elsewhere. A host should declare which theorems it accepts, what hardware it is bound to, and what state must survive when the rest of the machine is rebuilt or wiped clean.

## What It Controls

- hostname and system identity
- hardware configuration
- host-level profile enablement
- persistence declarations
- host-specific secrets wiring

## Layout

- `solanine/` is the current NixOS host.
- `solanine/system.nix` declares host identity and `system.stateVersion`.
- `solanine/profiles.nix` enables reusable `theorem.nixos.*` mechanisms.
- `solanine/storage.nix` declares filesystem and persistence details that must
  survive impermanence.
- `solanine/secrets.nix` binds encrypted secret names to their runtime destinations.

## Profile Doctrine

The host profile is where machine-shaped opinions become explicit: boot loader
family, Bluetooth radio posture, container compatibility layers, desktop
selection, gaming substrate, and the security elevation mechanism. Reusable
modules should provide theorem options for grouped mechanisms. For single
upstream settings, use native NixOS options directly instead of forging another
wrapper.

## Failure Modes

- Do not put reusable desktop, package, or service doctrine here unless it is genuinely host-specific.
- Do not change `system.stateVersion` as part of ordinary upgrades. It is a compatibility theorem, not a calendar.
- A missing profile enablement can make a module look broken when it was simply never asked to work.

## Maintenance Reminders

When adding another host, start by copying the shape, not the assumptions. Hardware, persistence, secrets, and deployment context all deserve fresh calibration.
