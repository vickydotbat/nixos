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
- Decide whether `nixcfg` should remain the repository group name or migrate to
  a clearer stewardship name such as `forge`. The group is not a replacement for
  `wheel`: `wheel` remains the local elevation and administrative role, while
  the repository group owns repair access to `/nix/nixos`, shared Git writes,
  and any narrow NixOS-operation authorization cache such as the `run0` profile.
  Do not widen application-control groups to guests or outside accounts just
  because the name changes.
- If the repository group is renamed, treat it as a real host migration. Update
  `repository.group`, user `extraGroups`, ownership and setgid state for
  `/nix/nixos`, `core.sharedRepository`, related documentation, and any module
  that derives access for repository stewards. Keep `admin` in every necessary
  administrative group, and verify that both `admin` and the daily operator can
  repair, rebuild, and commit after a fresh login.
- Validation: boot an installer or VM, run the bootstrap against a disposable
  disk, verify `/nix/nixos` is owned by `root:<repository-group>`, directory
  setgid is present, `core.sharedRepository` is `group`, `wheel` membership
  still grants elevation, and both `admin` and `vicky` can create and commit
  files after login.

## Repository Stewardship And Home Ownership

- Keep system-flake stewardship separate from personal Home Manager ownership.
  Membership in the repository group should mean "may repair this NixOS
  theorem", not "is the only kind of user allowed to configure a home
  environment". A normal local user should be able to own a personal Home
  repository without gaining write access to `/nix/nixos`.
- Export the shared Home Manager baseline in a shape that user-owned flakes can
  consume from their home directories. The preferred path should let a user keep
  something like `~/home-config` as their own Git repository, import this flake's
  reusable Home modules and defaults, and run their own Home activation without
  asking for membership in `nixcfg` or any future `forge` group.
- Treat system-managed imports of user-writable Home code as a privilege
  boundary. If `nixos-rebuild` imports a file from `/home/<user>`, that code is
  evaluated as part of the system theorem and can affect root-owned activation
  decisions. Do not auto-discover arbitrary home flakes. Any host-level import
  of user-owned Home configuration should be declared by a repository steward,
  limited to the named user and path, and reviewed for secrets, persistence, and
  service authority.
- Prefer a two-lane design: the system flake provides login accounts, groups,
  persistence substrate, shared modules, and safe defaults; personal Home flakes
  provide user-owned applications, themes, shell habits, editor posture, and
  other private working-surface choices. When a user's Home needs system
  integration such as service groups, SOPS material, login shell changes, or
  persistent directories, that integration remains a system-flake change with a
  clear reviewer and rollback path.
- Validation: create or simulate a non-repository user, evaluate the shared Home
  baseline without Vicky imports, and prove that the user can build or activate
  a personal Home flake from their own directory without write access to
  `/nix/nixos`. Separately prove that the system rebuild does not import
  user-writable Nix unless the host explicitly declares that trust gate.

## Module Hardening Queue

- Opened the conservative hardening ledger in
  [`docs/TODO-nixos-hardening.md`](./TODO-nixos-hardening.md). Use it to break
  hardening into small, tested mechanisms instead of one sharp global switch.
- Finish Btrfs rollback support before any host selects
  `theorem.nixos.base.persistence.root.mode = "btrfs"`. The option now exists
  to name the substrate, but the rollback-to-blank initrd rite still needs to be
  forged and tested against a disposable disk.
- Keep derived defaults where the dependency is real: graphics may follow
  graphical desktops or Steam, Home persistence may follow system persistence,
  and Polkit may follow Plasma. Optional applications, firewall openings, backup
  jobs, and hardware conveniences should remain explicit choices.
- Turn remaining host-shaped defaults into options before adding the next host:
  additional GPU vendor profiles still deserve sane defaults with host override
  points. Keep explicit theorem options for grouped mechanisms such as boot
  loader family, Bluetooth service hardening, and Podman compatibility features;
  use native NixOS options directly for single upstream settings such as SSH
  firewall exposure, boot generation limits, and graphics library toggles.
- Treat `run0` as a separate security profile until it has been activated and
  tested on a host. The profile now has a declared Polkit cache boundary and a
  configurable sudo compatibility alias, but the remaining rite is operational:
  prove login, elevation, rebuild, and rollback before making it a default.

## Home Module Boundary

- Keep reusable Home Manager modules focused on mechanisms and broadly useful
  defaults. User modules should carry themes, editor posture, shell habits,
  autostart choices, plugin-bearing packages, and language stacks that are only
  true for one operator.
- Continue the option-boundary pass before adding another user: Plasma layout,
  Ghostty key ownership, and shell aliases still need the same calibration that
  editors, Codex CLI policy, GIMP, Spicetify, ripgrep, nix-index, Discord
  autostart, Home SSH, Firefox search defaults, and KeePassXC posture now have.
- Move service-specific group membership out of static user registry entries
  where the service module can own it. A future Docker, Podman, or repository
  access module should add only the groups it creates or requires, with a clear
  failure mode when the backing service is disabled.
- NetworkManager is the first calibrated case: the base networking module grants
  the `networkmanager` group to selected users that already belong to `nixcfg`,
  keeping network control with repository stewards rather than with every local
  account or a single personal profile.
- Podman is now calibrated for the sharp case: rootless use needs no static
  user group, but enabling the Docker-compatible Podman socket grants the
  upstream-required `podman` group only to selected repository stewards. Keep
  `guest` outside that socket unless a host names the workflow and accepts the
  engine-control surface.
- Validation: evaluate a second user with the shared Home modules enabled and no
  Vicky profile imports. The result should install plain mechanisms, not Vicky's
  editor theme, VS Code workflow, GIMP plugin build, Spotify extensions, Discord
  autostart, command-not-found hook, or repository-specific ripgrep posture.


## In-File documentation

- Document every module and its settings inside its individual `.nix` file. If
  its configuration is relevant on a wider scale, also document it in a global
  or directory-based `README.md`. Ensure directory `README.md` files explain
  the broad-stroke purpose of the directory, and the root repository `README.md`
  explains how to navigate. Fold this into a long-term documentation standard
  or into the relevant readmes when the pattern settles.
- Progress: `modules/nixos/README.md` and `modules/home/README.md` now name the
  boundary between reusable system mechanisms, reusable Home mechanisms, host
  facts, and user-specific working-surface choices.

## YubiKey Support

- Research a YubiKey support module before binding any account or screen unlock
  path to a hardware key. The first mechanism should enable the local substrate:
  USB device access, `pcscd` or FIDO/U2F support as needed, browser and SSH
  compatibility, and diagnostics that prove the key is visible.
- Do not make YubiKeys mandatory MFA until loss and recovery are designed. The
  failure mode is severe: a misplaced token should not lock the operator out of
  the machine, secrets, or rebuild path.
- Decide which use cases belong in separate options: SSH resident keys, browser
  WebAuthn, LUKS or PAM unlock, KeePassXC challenge-response, and graphical
  screen unlock. Each one has a different recovery rite and should not be
  summoned by a single broad switch.
- Validation: test at least two physical keys, unplug one during login and
  unlock attempts, confirm recovery credentials still work, and document the
  command that proves the hardware path is available.

## Plasma Default Posture

- Decide whether new graphical hosts should select Plasma by default until a
  different desktop profile is explicitly enabled. Plasma is well supported in
  this flake today and gives new hosts a repairable fallback interface, but the
  default should remain a declared profile choice rather than a hidden import.
- Keep Wayland as the default display path. X11 should stay disabled or
  narrowly available unless a host names the application that still requires it.
  The failure mode is an older display server becoming an ambient attack surface
  because it was convenient during installation.
- Let window-manager profiles such as Hyprland, Sway, or Niri coexist with
  Plasma where their display-manager requirements allow it. Desktop environments
  that require their own login stack, such as GNOME with GDM, should disable or
  replace Plasma through explicit module logic.
- Split personal Plasma preferences from reusable defaults. The current Home
  Manager Plasma settings are close to Vicky's working surface; the reusable
  module should carry only broadly useful defaults, with themes, layout habits,
  and operator-specific shortcuts kept in user profiles.
- Validation: evaluate a new graphical host with no user-specific desktop
  imports, boot it in a VM if practical, confirm Wayland login works, confirm
  Plasma remains available after adding a compatible window-manager profile, and
  verify GNOME-style profiles make the replacement explicit.

## Philosophy

TODO: Fold the principles from the  below documentation into the current manifests where relevant. Use research and the existing principles in analysis, especially where concerns hardening.
<https://saylesss88.github.io/nix/index.html>
<https://saylesss88.github.io/nix/hardening_networking.html>
<https://saylesss88.github.io/nix/browsing_security.html>
<https://saylesss88.github.io/installation/enc/sops-nix.html>
<https://saylesss88.github.io/nix/gpg-agent.html>
<https://saylesss88.github.io/installation/enc/lanzaboote.html>
<https://saylesss88.github.io/nixos_containers.html>
<https://saylesss88.github.io/vcs/git.html>

I found this interesting, let's treat it as a research topic:
<https://saylesss88.github.io/vcs/jujutsu.html>
<https://saylesss88.github.io/vcs/practical_jj.html>
and the git repo <https://github.com/jj-vcs/jj>

Regarding nixpkgs, some more great documentation:
<https://saylesss88.github.io/Working_with_Nixpkgs_Locally_10.html>
<https://saylesss88.github.io/Package_Definitions_Explained_6.html>
