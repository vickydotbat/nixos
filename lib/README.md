# Lib

This directory holds small composition helpers.

At present, `mkSystem.nix` is the system assembly mechanism. It wires NixOS modules, Home Manager modules, overlays, shared arguments, and the selected host and user paths into one evaluated configuration.

## What It Controls

- recursive NixOS module imports through `import-tree`
- recursive Home Manager module imports through `import-tree`
- host path and user path composition
- overlays exposed from local packages and NUR
- shared inputs passed to modules

## Failure Modes

- Changing helper arguments can break every host that uses the helper.
- Moving module trees without updating `mkSystem.nix` can make whole categories disappear.
- Adding broad behavior here affects the full system. Prefer local modules unless the concern is truly composition-wide.

## Maintenance Reminders

Keep helpers boring and explicit. This file is close to the forge door; a small mistake here can make unrelated repairs look haunted.
