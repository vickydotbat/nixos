# Home

This directory holds user-level configuration.

The current user is `vicky`. Her identity module declares who she is; her profile module declares which reusable Home Manager theorems should be enabled; the raw tree preserves older extracted mechanisms that module wrappers still import.

## What It Controls

- Home Manager identity and state version
- user profile enablement under `theorem.home.*`
- raw Home Manager fragments used by wrapper modules
- shell, desktop, editor, web, and game tooling

## Layout

- `users/vicky/identity.nix` declares username, home directory, Home Manager state, and session variables.
- `users/vicky/profiles.nix` enables reusable Home Manager mechanisms.
- `raw/vicky/` contains implementation fragments imported by modules under `modules/home/`.

## Failure Modes

- Do not move raw fragments without updating the wrapper modules that import them.
- Do not change `home.stateVersion` as an ordinary upgrade habit. It preserves Home Manager compatibility.
- If a feature is declared in `modules/home/` but absent from `users/vicky/profiles.nix`, it will remain dormant.

## Maintenance Reminders

Prefer adding new reusable behavior under `modules/home/`, then enabling it in the user profile. Put only identity and user-specific calibration directly under `home/users/vicky/`.
