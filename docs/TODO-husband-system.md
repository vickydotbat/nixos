# Managed Desktop TODO

This is the project ledger for a click-first managed desktop user. The
motivating case is a household user who should receive a familiar graphical
desktop, working game and Windows-compatibility launchers, and durable personal
state without becoming a repository steward or a NixOS operator.

The goal is not to imitate Windows inside the machine. The goal is humane
desktop stewardship: Vicky or another maintainer owns the system theorem; the
managed user launches applications, games, files, settings, and compatibility
tools from graphical surfaces; mutable app-store behavior is allowed only where
the contract names it.

Option paths and package names mentioned here were checked against
`.#nixosConfigurations.solanine` on 2026-06-04. Re-verify them when
implementation begins; option spelling, package availability, and mutability
are part of the mechanism.

## Current State

- `nixosConfigurations.firelink` is now a buildable managed-desktop test host
  with a disko layout: 1 GiB EFI, LUKS `cryptroot` over the remaining disk,
  Btrfs subvolumes for `@root`, `@root-blank`, `@nix`, `@persist`, and `@swap`,
  and a 16 GiB encrypted-at-rest Btrfs swapfile under `/.swapvol`. The disk
  device is deliberately `CHANGE-ME` until the target drive is named.
- The host selects only `admin` as a repair account for now. It still needs a
  host-owned SOPS file, password secret wiring, and the actual managed desktop
  user before activation on real hardware.
- `users/guest/default.nix` is an opt-in low-access account with no password
  secret, no Home Manager profile, no SSH material, and no supplementary groups.
  It is not yet a managed desktop user.
- `users/README.md` says new working accounts must name their workflow before
  receiving Home Manager or persistence. It also keeps `guest` and outside
  accounts away from repository stewardship and service groups unless a host
  accepts the risk.
- `lib/mkSystem.nix` imports Home Manager only for selected users whose user
  doctrine sets `home.enable = true`. This is the current system-managed Home
  trust gate.
- `modules/nixos/desktop/plasma.nix` owns the reusable Plasma login stack and
  desktop service.
- `modules/nixos/desktop/flatpak.nix` exposes
  `theorem.nixos.desktop.flatpak.enable` and persists `/var/lib/flatpak` when
  system persistence is enabled.
- `modules/nixos/desktop/appimage.nix` exposes
  `theorem.nixos.desktop.appimage.enable` and maps it to
  `programs.appimage.enable` plus `programs.appimage.binfmt`.
- `modules/nixos/gaming/core.nix` and `modules/nixos/gaming/steam.nix` own
  current gaming substrate. The larger launcher/performance follow-up lives in
  `docs/TODO-nixos-gaming.md`.
- `modules/home/base/xdg.nix` already declares `Applications`, `Games`,
  `Documents`, `Downloads`, `Desktop`, and other XDG-oriented directories.
- `modules/home/base/persistence.nix` persists common user directories when
  Home persistence is enabled, but it currently makes `Downloads` volatile by
  default.

This means the project should begin by calibrating account, Home, persistence,
and mutable-app boundaries. Do not create a duplicate `compat` hierarchy until
the existing `desktop` and `gaming` modules prove too blunt for this profile.

## Doctrine For This Project

- The managed desktop user is a normal account, not an administrator. Do not
  add it to `wheel`, `nixcfg`, or Nix daemon `trusted-users` by default.
- Vicky's system repository remains root-controlled and stewarded by declared
  repository users. The managed user must not be able to modify `/nix/nixos`.
- Graphical usability is a real requirement, not decoration. Plasma, Discover,
  Flatpak, AppImage, Steam, Bottles, Heroic, Lutris, Dolphin, System Settings,
  and file associations should be reachable without terminal habits.
- Mutable GUI installation is allowed only where it is named. Flatpak through
  Discover can be part of the managed desktop contract; direct Nix package
  installation by the managed user should stay out of scope.
- Application state belongs to the managed user's home. Wine prefixes, Bottles,
  Steam libraries, Flatpak data, AppImage launchers, game saves, and user files
  must not bleed into Vicky's home.
- Persistence should be more ordinary than Vicky's workshop, but not blind.
  Persist the state that a non-terminal user reasonably expects to survive;
  avoid binding all of `$HOME` unless a later host explicitly accepts that
  simpler, broader model.
- Hardening remains calibrated. Flatpak, AppImage, Wine, game launchers, input
  devices, portals, user namespaces, FUSE, and Polkit all widen or stress
  security surfaces. Name the workflow before tightening or granting.
- Keep helpers boring. A Nix-built `.desktop` launcher or KDE service menu is
  acceptable if it is readable and removable. Hidden shell magic is not repair.

## Verified Surfaces

| Surface | Current Status | Notes |
|---|---|---|
| Plasma | `services.desktopManager.plasma6.enable`; `services.displayManager.plasma-login-manager.enable` | Current module uses Plasma Login Manager because SDDM is marked unsupported for this pinned release. |
| Flatpak | `services.flatpak.enable` | Existing module persists `/var/lib/flatpak` with system persistence. |
| Portals | `xdg.portal.enable`; `xdg.portal.extraPortals` | Required for Flatpak, screenshots, file choosers, and desktop integration. |
| AppImage | `programs.appimage.enable`; `programs.appimage.binfmt` | Existing module enables both. |
| Discover | `pkgs.kdePackages.discover` exists | Needs package review and runtime check for Flatpak backend behavior. |
| KDE portal | `pkgs.kdePackages.xdg-desktop-portal-kde` exists | Plasma usually provides this path; verify generated portal config before adding explicit packages. |
| Launchers | `pkgs.bottles`, `pkgs.lutris`, `pkgs.heroic`, `pkgs.protonup-qt` exist | Should be mostly user-owned or gaming-profile-owned, not base desktop defaults. |
| Wine tooling | `pkgs.winetricks`; `pkgs.wineWow64Packages.staging` exists | `wineWowPackages` is deprecated; use `wineWow64Packages`. |
| Gaming tools | `pkgs.mangohud`, `pkgs.goverlay`, `pkgs.steam-run` exist | Coordinate with `docs/TODO-nixos-gaming.md`. |
| Flatseal | No top-level `pkgs.flatseal` matched on 2026-06-04 | Research package movement or use Flatpak permission docs before promising it. |

## Project Shape

The first implementation should be a managed-user and managed-Home project, not
a sweeping desktop rewrite.

Recommended boundaries:

- `users/<managed-user>/` owns identity, UID, password secret, avatar, Home
  entry point, and selected personal profile.
- `hosts/<host>/profiles.nix` decides whether the managed user belongs on that
  host and which system substrates are enabled.
- `modules/nixos/desktop/*` continues to own Plasma, Flatpak, AppImage,
  Bluetooth, graphics, audio, and other root-owned desktop substrate.
- `modules/nixos/gaming/*` continues to own Steam, GameMode, Gamescope, and
  root-owned gaming integration.
- `modules/home/*` owns user-facing launcher entries, MIME defaults, XDG
  directories, Home persistence, and per-user application selections.
- A future `theorem.home.profiles.managedDesktop.enable` may compose Home
  modules if repeated managed users appear. Do not add it until one user's
  profile proves which settings are truly reusable.

Avoid a first pass shaped like
`modules/nixos/profiles/managed-desktop.nix` if it merely renames existing
options. Add a profile module only when it prevents real selection mistakes.

## Phase 1: Account And Authority

- [ ] Decide whether the managed desktop user reuses `guest` or becomes a new
  named account.
  - Why: `guest` currently means temporary low-access account, while this
    project needs durable personal state, password management, Home Manager, and
    application ownership.
  - How: choose one role. If this is a real household account, create a new
    `users/<name>/` entry instead of overloading `guest`. Keep UID, description,
    avatar, password secret, and Home module path declared beside the account.
  - Achieves: account meaning stays honest.
  - Validation: evaluate `selectedUsers`, confirm the account appears only on
    hosts that select it, and confirm `guest` remains low-access if it still
    exists.

- [ ] Keep the managed user outside repository stewardship.
  - Why: write access to `/nix/nixos`, membership in `nixcfg`, and Nix daemon
    trust are system-repair authority.
  - How: ensure the managed user's `extraGroups` omits `wheel` and `nixcfg`.
    Check that `modules/nixos/base/nix-trusted-users.nix` does not derive Nix
    daemon trust for the account.
  - Achieves: the user can use the desktop without becoming an operator.
  - Validation: targeted eval of `users.users.<name>.extraGroups`,
    `nix.settings.trusted-users`, and repository permissions after login.

- [ ] Design service-group grants for non-steward desktop users.
  - Why: existing group doctrine grants application groups to repository
    stewards by default. A managed desktop user may still need NetworkManager,
    input, video, Bluetooth, scanner, printer, or controller access.
  - How: add explicit host or module options for non-steward access instead of
    widening every service group to every local user. Start with the smallest
    set required for the actual workflow.
  - Achieves: usability without hidden privilege expansion.
  - Validation: login as the managed user, test network GUI, Bluetooth, audio,
    controller, removable-media, and printing/scanning only where selected.

- [ ] Add a password and recovery rite before enabling the account on a real
  host.
  - Why: `users.mutableUsers = false` means the account must have declared
    credentials or an intentional passwordless workflow.
  - How: create a SOPS-backed password hash secret if the account is durable.
    Document who can reset it and how `admin` recovers the machine if the
    managed user's Home profile breaks.
  - Achieves: login is reproducible and recovery remains separate.
  - Validation: `nix eval` sees the secret path, rebuild dry-builds, and both
    `admin` and the managed user can log in after activation.

## Phase 2: Base Graphical Desktop

- [ ] Define the managed desktop baseline on top of the existing Plasma module.
  - Why: a click-first user needs a reliable login manager, menus, settings,
    file manager, portal behavior, and Polkit prompts.
  - How: use `theorem.nixos.desktop.plasma.enable`, graphics, audio, Polkit,
    and the current Plasma Login Manager path. Do not fork Plasma settings into
    a managed profile until the reusable defaults are known.
  - Achieves: the account receives a stable graphical surface without a new
    login-stack doctrine.
  - Validation: boot the host or a VM, log in as the managed user, open Dolphin,
    System Settings, Discover, browser, and a file chooser.

- [ ] Add Discover only after package inventory review.
  - Why: Discover is useful for GUI software and firmware workflows, but it can
    imply PackageKit, Flatpak, firmware, or update surfaces depending on how it
    is configured.
  - How: review `pkgs.kdePackages.discover`, confirm Flatpak backend behavior,
    decide whether PackageKit/Nix package installation remains disabled, and
    keep firmware refresh behavior aligned with `modules/nixos/desktop/plasma.nix`.
  - Achieves: Discover becomes the user's app-store door without becoming an
    unmanaged system update door.
  - Validation: Discover opens as the managed user, sees Flathub if configured,
    does not offer unapproved Nix system mutation, and firmware actions require
    the intended authorization.

- [ ] Keep browser choice explicit.
  - Why: browsers carry security, privacy, password-manager, MIME, and
    persistence behavior. A managed user may need a friendly daily browser, not
    Vicky's exact web posture.
  - How: decide whether to use the existing Firefox module, a simpler Home
    browser profile, or a host-selected package. Avoid importing Vicky's web
    profile wholesale.
  - Achieves: web access is usable without inheriting a private workshop.
  - Validation: launch browser, test downloads, login persistence, file
    associations, password-manager expectations, and default MIME handlers.

## Phase 3: Flatpak And Mutable GUI Apps

- [ ] Decide the Flatpak contract: mutable user install, declarative install,
  or mixed.
  - Why: Flatpak is probably the best click-install surface for a non-terminal
    NixOS user, but it introduces mutable state and permission policy.
  - How: document whether the managed user may install Flatpaks through
    Discover. If yes, call that accepted mutable state. If no, design a
    declarative app list and explain how new apps are requested.
  - Achieves: reproducibility tradeoffs are visible instead of hidden behind a
    friendly app store.
  - Validation: install a harmless Flatpak as the managed user if mutable mode
    is accepted, reboot through impermanence, and confirm state persists only
    where declared.

- [ ] Add Flathub deliberately.
  - Why: Flatpak without a remote is not a useful app store; Flathub is also an
    external package feed with its own trust and update cadence.
  - How: decide whether to add Flathub through a system activation script, a
    Home activation step, or a community module after review. Avoid ad hoc
    shell fragments unless they are idempotent and clearly owned.
  - Achieves: the user can install common GUI apps without terminal work.
  - Validation: `flatpak remotes` shows the expected remote, Discover can browse
    it, and `docs/package-inventory.md` or a focused note records the trust
    tradeoff.

- [ ] Research Flatpak permission management before promising Flatseal.
  - Why: no top-level `pkgs.flatseal` exists in the pinned package set checked
    on 2026-06-04, and Flatpak permissions are the real hardening surface.
  - How: search the pinned package set and Flatpak packaging state, then decide
    whether permissions are managed through a packaged GUI, `flatpak override`,
    declarative home state, or documentation.
  - Achieves: permission control does not depend on a package that may not
    exist in this input.
  - Validation: inspect permissions for one installed app and prove the chosen
    override method survives reboot where intended.

## Phase 4: AppImage Support

- [ ] Keep AppImage execution behind the existing desktop module.
  - Why: AppImage support uses binfmt/FUSE convenience and belongs to hosts that
    deliberately run vendor binaries.
  - How: use `theorem.nixos.desktop.appimage.enable`; do not introduce a second
    `theorem.nixos.compat.appimage` name until there is a real boundary repair.
  - Achieves: one option owns AppImage system substrate.
  - Validation: `programs.appimage.enable` and `programs.appimage.binfmt`
    evaluate true only on selected hosts.

- [ ] Define the managed `~/Applications` convention.
  - Why: a non-terminal user needs a predictable place for AppImages and vendor
    downloads.
  - How: reuse the XDG `APPS = "$HOME/Applications"` directory from
    `modules/home/base/xdg.nix`, create it through Home/XDG setup, and decide
    whether it is persistent.
  - Achieves: AppImages have a named home instead of scattering through
    Downloads.
  - Validation: `~/Applications` exists after login, persists if selected, and
    the user can open it from Dolphin or a desktop launcher.

- [ ] Research double-click and desktop integration for AppImages.
  - Why: `programs.appimage.binfmt` may make execution work, but launchers,
    executable bits, icons, MIME behavior, and desktop entries are separate
    usability pieces.
  - How: test one known AppImage. Decide whether to provide a `.desktop` helper,
    Dolphin service menu, or documentation. Avoid automatic `chmod` over broad
    directories unless the security tradeoff is named.
  - Achieves: AppImage support is graphical and understandable.
  - Validation: the managed user can run the test AppImage from Dolphin, see any
    intended launcher integration, and remove it without root.

## Phase 5: Windows Applications And Game Launchers

- [ ] Prefer graphical wrappers over raw Wine.
  - Why: a click-first user should not manage Wine prefixes by hand.
  - How: coordinate with `docs/TODO-nixos-gaming.md` to add or select Bottles,
    Lutris, Heroic, ProtonUp-Qt, `winetricks`, and `wineWow64Packages.staging`
    in the right Home or system boundary. Keep raw Wine available only as
    substrate where the wrappers need it.
  - Achieves: Windows applications are installed through visible tools and kept
    in the managed user's home.
  - Validation: install or launch one harmless Windows program through the
    chosen wrapper and inspect that the prefix lands under the managed user's
    declared state.

- [ ] Keep launcher packages user-owned unless root integration is required.
  - Why: Lutris, Heroic, Bottles, ProtonUp-Qt, and similar tools are optional
    applications with user-local state.
  - How: choose Home modules or the managed user's profile before adding these
    to `environment.systemPackages`. Use system modules only for services,
    udev, graphics, Steam hardware, or other root-owned substrate.
  - Achieves: another user can have a different launcher set without changing
    the host theorem.
  - Validation: `checks/home-shared-boundary.nix` still proves shared Home
    modules do not import Vicky's profile, and the managed user's Home build
    includes only selected launchers.

- [ ] Keep Steam and performance work delegated to the gaming ledger.
  - Why: Steam, Proton-GE, MangoHud, GameMode, Gamescope, and launcher packages
    already have a dedicated repair path.
  - How: use the existing gaming module for Steam and GameMode, then consume
    the follow-up from `docs/TODO-nixos-gaming.md` when it lands. Do not add
    custom kernels, Mesa-git, scheduler tweaks, or global compiler flags to this
    profile.
  - Achieves: managed desktop usability does not become a performance
    experiment.
  - Validation: Steam launches, a Proton game launches, GameMode works, and
    experimental gaming options remain disabled.

## Phase 6: Home Profile And Persistence

- [ ] Create a managed Home profile only after the target account is chosen.
  - Why: Home Manager owns the user's working surface. A profile written before
    the account exists can drift into generic assumptions or Vicky-specific
    habits.
  - How: add `users/<name>/home.nix`, `identity.nix`, and focused profile files
    following the Vicky split only where useful. Keep shell/editor/developer
    tooling out unless the user needs it.
  - Achieves: the user receives a small, readable Home theorem.
  - Validation: Home builds through the system flake and does not import Vicky's
    Home files.

- [ ] Adjust Home persistence for ordinary desktop expectations.
  - Why: Vicky's volatile Downloads policy may be surprising for a non-terminal
    user who expects downloaded installers, photos, and documents to survive.
  - How: set `theorem.home.base.persistence.volatileDownloads.enable = false`
    for the managed user if persistence is enabled. Add explicit directories
    for Flatpak, Bottles, Lutris, Heroic, Steam, Wine prefixes, desktop files,
    MIME data, icons, and user documents only after actual paths are verified.
  - Achieves: important user data survives without persisting all of `$HOME`.
  - Validation: create files in Documents, Downloads, Applications, Games, and
    one launcher prefix; reboot through impermanence; confirm intended state
    remains and an undeclared test path is wiped.

- [ ] Separate system rollback from user-state recovery.
  - Why: NixOS generation rollback does not roll back Flatpak installs, Wine
    prefixes, Steam libraries, game saves, or documents.
  - How: write a short managed-desktop recovery note once the first profile is
    implemented. Name which state is persistent, which state is mutable, and
    how an operator repairs a broken Home profile from `admin`.
  - Achieves: a failed experiment does not leave the maintainer guessing which
    layer changed.
  - Validation: perform a dry build, a Home activation check, and at least one
    rollback or test-generation recovery before selecting the profile by
    default.

## Phase 7: Click-Oriented UX

- [ ] Build a curated launcher set before clever helpers.
  - Why: menus and visible applications solve most non-terminal workflows with
    less fragility than scripts.
  - How: ensure Discover, Dolphin, System Settings, browser, Steam, Heroic,
    Lutris, Bottles, ProtonUp-Qt, Applications folder, and Games folder are
    available through Plasma menus or desktop entries where selected.
  - Achieves: the user has obvious doors for common tasks.
  - Validation: log in fresh and complete a checklist without opening a
    terminal.

- [ ] Add helper launchers only for repeated pain.
  - Why: `Install Windows Program`, `Run AppImage`, `Open Games Folder`, and
    `Repair Steam` helpers may be useful, but each script becomes a maintenance
    mechanism.
  - How: if needed, build helpers as Nix packages or Home-managed `.desktop`
    files using readable commands and `kdialog` or another graphical prompt.
    Document what each helper modifies and how to remove it.
  - Achieves: convenience without hidden state machines.
  - Validation: each helper works as the managed user, fails clearly when its
    backend is absent, and leaves no root-owned files in the user's home.

- [ ] Define MIME and file association defaults.
  - Why: double-click behavior is central to the profile. Poor defaults make the
    desktop feel broken even when packages are installed.
  - How: add Home-managed MIME defaults for common file types only after
    selecting the actual applications. Avoid Vicky's browser or editor defaults
    unless they are intended for this user too.
  - Achieves: files open through expected graphical applications.
  - Validation: test HTML links, PDFs, archives, images, videos, AppImages,
    `.exe` files where applicable, and common document types.

## Phase 8: Hardening And Compatibility

- [ ] Add managed desktop signals to `docs/hardening-compatibility.md`.
  - Why: this profile combines Flatpak, AppImage, Wine, gaming launchers,
    portals, Polkit, input devices, and mutable user state.
  - How: add rows for the managed desktop user/profile once option names are
    chosen. Include known conflicts with SUID wrapper minimization, user
    namespaces, hardened kernels, hardened allocators, USBGuard, Bluetooth
    service hardening, portals, and volatile logs.
  - Achieves: hardening work can see the profile before it breaks the user.
  - Validation: every row names the host signal, breakage, and gate before
    enabling a sharp setting.

- [ ] Keep the managed user out of container and repository authority by
  default.
  - Why: Docker-compatible Podman sockets, repository groups, and Nix daemon
    trust are broad authority surfaces.
  - How: do not grant `podman`, Docker socket groups, `nixcfg`, or trusted Nix
    status unless a host names the workflow.
  - Achieves: a compromised browser, game, or Windows program has less reach.
  - Validation: inspect groups and verify the user cannot write `/nix/nixos` or
    control the container engine unless explicitly selected.

- [ ] Test Polkit prompts without making the user an administrator.
  - Why: a GUI user needs normal desktop prompts, but admin authorization should
    still belong to `admin` or another steward.
  - How: test NetworkManager, Bluetooth, Discover, removable media, printer
    setup, and firmware-related prompts with the chosen groups and Polkit
    profile.
  - Achieves: usable desktop prompts without `wheel`.
  - Validation: ordinary actions work; privileged actions require an
    administrator credential or are unavailable by design.

## Phase 9: Validation Rites

Run these from the local NixOS checkout for the target host unless the execution
context changes. `solanine` currently uses the `sudo` security profile; if a
future host selects `run0-sudo`, use that host's active elevation mechanism for
runtime checks.

- [ ] Verify existing NixOS option surfaces.
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.services.flatpak --apply 'opts: builtins.attrNames opts'`
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.programs.appimage --apply 'opts: builtins.attrNames opts'`
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.xdg.portal --apply 'opts: builtins.attrNames opts'`
  - Expected: Flatpak exposes `enable`; AppImage exposes `enable` and `binfmt`;
    portals expose `enable` and `extraPortals`.

- [ ] Verify package availability before package-bearing work.
  - Command: `nix eval --json .#nixosConfigurations.solanine.pkgs --apply 'pkgs: builtins.map (name: { inherit name; present = builtins.hasAttr name pkgs; }) [ "appimage-run" "flatpak" "bottles" "lutris" "heroic" "protonup-qt" "winetricks" "mangohud" "goverlay" "steam-run" ]'`
  - Expected: every required package for the selected milestone is present, or
    the missing package becomes a research task.

- [ ] Verify account authority.
  - Command: `nix eval --json .#nixosConfigurations.solanine.config.users.users.<name>.extraGroups`
  - Command: `nix eval --json .#nixosConfigurations.solanine.config.nix.settings.trusted-users`
  - Expected: the managed user is not in `wheel`, `nixcfg`, or Nix trusted
    users unless a host explicitly chose that authority.

- [ ] Run repository checks.
  - Command: `nix flake check`
  - Expected: the flake evaluates, including `checks/home-shared-boundary.nix`.

- [ ] Dry-build the target host before activation.
  - Command: `nixos-rebuild dry-build --flake .#solanine`
  - Expected: the host builds without switching.

- [ ] Run runtime checks after activation.
  - Managed user can log in graphically.
  - Managed user cannot write to `/nix/nixos`.
  - Plasma menus show the selected launcher set.
  - Discover opens and has only the intended app/update authority.
  - Flatpak install or declarative Flatpak app behavior matches the chosen
    contract.
  - AppImage execution works through the intended graphical path.
  - Steam and selected launchers open without terminal work.
  - Bottles or the selected Windows-app wrapper creates state in the managed
    user's home only.
  - Documents, Downloads, Applications, Games, and selected app data survive
    impermanence only where declared.
  - `admin` can still repair, rebuild, and roll back the host.

## Deferred Until The First Profile Works

- A broad `theorem.nixos.profiles.managedDesktop.enable` composer.
- A new `modules/nixos/compat/` tree that duplicates existing desktop modules.
- Declarative Flatpak app installation beyond Flathub setup and persistence.
- Flatseal or any permission GUI until package availability is resolved.
- Automatic AppImage chmod, icon extraction, or desktop-entry generation.
- Kiosk mode, auto-login, or forced Steam Big Picture startup.
- Exposing Nix package installation through Discover or PackageKit.
- Adding the managed user to `wheel`, `nixcfg`, Docker-compatible Podman, or
  Nix trusted users.
- Custom gaming kernels, Mesa-git, global compiler flags, scheduler tweaks, or
  aggressive sysctls.
- Persisting all of `$HOME` as the default.

## Suggested Implementation Order

1. Choose the account role and add a durable managed user entry if `guest` is
   the wrong name.
2. Give that account a minimal Home Manager profile with XDG directories and
   ordinary desktop persistence.
3. Select Plasma, Flatpak, AppImage, graphics, audio, Polkit, and the existing
   gaming substrate from the host profile.
4. Add Discover and the first launcher set after package inventory review.
5. Define the Flatpak contract and Flathub setup.
6. Test AppImage and Windows-app wrapper behavior as the managed user.
7. Update hardening compatibility with the final option names.
8. Run targeted evals, `nix flake check`, and `nixos-rebuild dry-build`.
9. Activate only after `admin` recovery and rollback remain proven.
