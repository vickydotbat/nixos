# Home

This directory holds user identity, profile selection, and user-specific
overrides.

The current user is `vicky`. Her identity module declares who she is; her
profile module declares which reusable Home Manager theorems should be enabled.
Reusable defaults live under `modules/home/`, not here. This keeps the repair
boundary visible: modules provide the mechanism, users choose and calibrate it.

## What It Controls

- Home Manager identity and state version
- user profile enablement under `theorem.home.*`
- user-specific overrides that should not become global defaults

## Layout

- `users/vicky/identity.nix` declares username, home directory, Home Manager state, and session variables.
- `users/vicky/profiles.nix` enables reusable Home Manager mechanisms and
  records deliberate overrides. Some modules also derive sane defaults from
  system or user theorems.

## Failure Modes

- Do not put reusable defaults here. A setting placed in `home/users/<user>/`
  should be personal calibration, not the default theorem future users inherit.
- Do not change `home.stateVersion` as an ordinary upgrade habit. It preserves Home Manager compatibility.
- If a feature is absent from `users/vicky/profiles.nix`, check its module
  default before assuming it is dormant. Substrates such as fonts, XDG
  directories, and persistence may follow the features they serve.
- Optional applications, games, backup jobs, hardware conveniences, and
  compatibility layers should be explicit choices in the profile. Reproducible
  means the chosen shape is visible in the theorem, not inferred from whatever
  happened to be nearby.

## Maintenance Reminders

Prefer adding reusable behavior under `modules/home/`, then enabling it in the
user profile. Put only identity, profile selection, and user-specific
calibration directly under `home/users/vicky/`.
