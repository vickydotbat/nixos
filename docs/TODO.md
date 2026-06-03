# TODO

This is the repair ledger for work that should become configuration, not a pile
of hopeful comments. Each item should name the mechanism, the failure mode, and
the validation rite that proves it still holds.

## Bootstrap And Spawning

- Add a first-install bootstrap path built around `disko` plus explicit
  initialization scripts. The installer rite should partition and mount the
  target, restore or create secret material, clone the flake into
  `/nix/nixos`, calibrate it for the `nixcfg` group, and only then
  run the first rebuild. Without this, the shared group exists only after the
  system has already evaluated the repository it was meant to protect.
- Decide whether this belongs as a host-specific script, a flake app, or a
  dedicated installation profile. The correct shape should make destructive disk
  actions impossible to run without naming the target device and host.
- Validation: boot an installer or VM, run the bootstrap against a disposable
  disk, verify `/nix/nixos` is `root:nixcfg`, directory setgid is
  present, `core.sharedRepository` is `group`, and both `admin` and `vicky` can
  create and commit files after login.

## Module Hardening Queue

- Finish Btrfs rollback support before any host selects
  `theorem.nixos.base.persistence.root.mode = "btrfs"`. The option now exists
  to name the substrate, but the rollback-to-blank initrd rite still needs to be
  forged and tested against a disposable disk.
- Keep derived defaults where the dependency is real: graphics may follow
  graphical desktops or Steam, Home persistence may follow system persistence,
  and Polkit may follow Plasma. Optional applications, firewall openings, backup
  jobs, and hardware conveniences should remain explicit choices.
- Turn remaining host-shaped defaults into options before adding the next host:
  boot loader family, networking backend, SSH exposure, Bluetooth posture,
  Podman compatibility features, and GPU vendor support all deserve sane defaults
  with host override points.
- Treat `run0` as a separate security profile until the per-user authorization
  model is real. A placeholder username in an authorization rule is not a
  mechanism; it is a warning light.
