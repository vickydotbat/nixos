# NixOS Gaming TODO

This is the gaming repair ledger for this repository. It distills the old
CachyOS, SteamOS, Bazzite, and Nobara research into small mechanisms that can
be reviewed, built, measured, and rolled back.

The goal is not to turn Solanine or any future host into a SteamOS clone. The
goal is a clear gaming theorem: Steam and compatibility tools where selected,
graphics and audio substrate where needed, performance experiments behind
explicit host gates, and enough observability to prove whether an optimization
helped or merely sounded impressive.

Option paths and package names mentioned here were checked against
`.#nixosConfigurations.solanine` on 2026-06-04. Re-verify them when
implementation begins; NixOS option names are part of the mechanism.

## Current State

- `modules/nixos/gaming/core.nix` owns the shared gaming substrate. Today that
  means `programs.gamemode.enable = true` when the gaming core is selected.
- `modules/nixos/gaming/steam.nix` owns the explicit Steam profile, Steam
  firewall choices, Steam hardware support, unfree package predicates for Steam,
  `steam-run`, and an opt-in Steam Gamescope session.
- `modules/nixos/desktop/graphics.nix` derives graphics support from Plasma,
  Steam, or Jailwolf and already enables `hardware.graphics.enable` plus
  `hardware.graphics.enable32Bit` by default when graphics are needed.
- `modules/nixos/desktop/audio.nix` derives PipeWire from Plasma or Steam.
- `modules/home/gaming/steam.nix` adds Home persistence for
  `.local/share/Steam` only when the surrounding NixOS theorem selected Steam
  and Home persistence is available.
- `hosts/solanine/profiles.nix` currently selects `gaming.core.enable = true`
  and `gaming.steam.enable = true`.

This means the next work should refine a living substrate, not create a broad
new namespace from nothing.

## Doctrine For This Project

- Keep gaming explicit. Steam, launchers, Wine prefixes, hardware convenience
  services, and firewall openings are profile choices, not base-system drift.
- Keep unfree software visible through
  `theorem.nixos.base.nix.unfreePackageNames`; do not set
  `nixpkgs.config.allowUnfree = true`.
- Keep performance claims measurable. A kernel, scheduler, compositor, or
  graphics-stack change needs a before/after note or it remains research.
- Keep hardening compatibility in view. Gaming touches user namespaces, SUID or
  capability-bearing helpers, Xwayland, portals, controller devices, firewall
  ports, and large user-writable state.
- Keep experiments reversible. CachyOS kernels, Mesa-git, exotic compiler
  flags, handheld daemons, USB polling changes, and auto-login belong behind
  host selection, specialization, or a disposable test host.
- Keep Home and system boundaries clean. System modules install root-owned
  substrate. User profiles own personal launchers, game-specific tooling,
  per-user MangoHud preferences, Wine prefixes, and library locations unless a
  host-level integration is required.

## Source Distillation

| Source | Useful Lesson | Repository Translation |
|---|---|---|
| CachyOS | Kernel and compiler tuning can improve responsiveness, but benefits are workload-specific and cache-expensive. | Treat alternate kernels and LTO as explicit experiments. Do not make CachyOS or `-march=native` the default. |
| SteamOS | The console experience is mostly Gamescope plus a Steam session and frame-pacing controls. | Keep Steam desktop mode separate from an HTPC or Gamescope-session profile. No auto-login by default. |
| Bazzite | Integration matters: Steam, launchers, controller support, HDR/VRR, and atomic rollback posture. | NixOS generations already cover rollback; port the integration ideas, not the Fedora Atomic model. |
| Nobara | Gaming distros often ship codecs, WINE dependencies, patched Gamescope, capture tools, and hardware quirks. | Add package-bearing mechanisms only when this repo names their package review, persistence, and rollback path. |

Keep the old research links as handles to revisit, not as authority to import
settings wholesale:

- CachyOS kernel: <https://wiki.cachyos.org/features/kernel/>
- CachyOS gaming guide: <https://wiki.cachyos.org/configuration/gaming/>
- Nix CachyOS kernel flake: <https://github.com/xddxdd/nix-cachyos-kernel/>
- Gamescope: <https://github.com/ValveSoftware/gamescope>
- Bazzite: <https://bazzite.gg/>
- Bazzite FAQ: <https://docs.bazzite.gg/General/FAQ/>
- Nobara: <https://nobaraproject.org/>
- Nobara kernel modifications: <https://wiki.nobaraproject.org/modifications/kernel>
- Nobara package modifications: <https://wiki.nobaraproject.org/modifications/packages>
- NixOS Steam wiki: <https://wiki.nixos.org/wiki/Steam>

## Phase 1: Baseline Audit And Documentation

- [ ] Write `docs/gaming-performance.md`.
  - Why: performance work without a measurement rite becomes folklore.
  - How: document the current Solanine gaming stack, the portable lessons from
    CachyOS/SteamOS/Bazzite/Nobara, rejected shortcuts, benchmark commands,
    rollback steps, and the manual runtime checks listed below.
  - Achieves: a stable note future maintainers can read before enabling a
    sharper gaming profile.
  - Validation: the document names at least one Steam/Proton game or repeatable
    benchmark path, a MangoHud logging path, the active kernel version, the GPU
    driver shown by Vulkan tooling, and the rollback generation rite.

- [ ] Add a gaming row set to `docs/hardening-compatibility.md`.
  - Why: Steam, Wine, launchers, Gamescope, and anti-cheat-adjacent workloads can
    collide with hardening choices around user namespaces, SUID wrappers,
    capabilities, portals, Xwayland, and coredump/log policy.
  - How: add host signals for `theorem.nixos.gaming.steam.enable`,
    `theorem.nixos.gaming.core.enable`, future Gamescope session selection,
    future launcher modules, and future alternate kernel selection.
  - Achieves: hardening changes will see gaming as a declared workload instead
    of breaking it as an accidental desktop side effect.
  - Validation: each new matrix row names the known breakage and the gate before
    enablement.

- [ ] Run the package inventory rite for the gaming stack.
  - Why: gaming packages are large, often unfree, and often launch user-writable
    code or compatibility runtimes.
  - How: review current and candidate packages with `docs/package-inventory.md`.
    Start with `steam`, `steam-run`, `proton-ge-bin`, `mangohud`, `goverlay`,
    `protonup-qt`, `lutris`, `heroic`, `bottles`, `vkbasalt`, and
    `wineWow64Packages.staging`.
  - Achieves: package-bearing additions are visible at the mechanism that needs
    them.
  - Validation: targeted `nix eval` confirms package presence in the pinned
    package set, and any unfree package is admitted by exact package name rather
    than a global allow switch.

## Phase 2: Repair Existing Gaming Boundaries

- [ ] Tighten `modules/nixos/gaming/core.nix` around GameMode.
  - Why: GameMode is the current shared gaming substrate, but the option surface
    only exposes a broad enable bit.
  - How: add options for `programs.gamemode.enableRenice` and any minimal
    `programs.gamemode.settings` this repository actually needs. Keep defaults
    conservative and overrideable.
  - Achieves: frame-pacing and priority behavior become declared policy instead
    of hidden upstream defaults.
  - Validation: evaluate
    `.#nixosConfigurations.solanine.config.programs.gamemode`, dry-build the
    host, and after activation run a GameMode test command such as
    `gamemoderun true`.

- [ ] Split Steam session concerns from the Steam package profile.
  - Why: `theorem.nixos.gaming.steam.enable` should install and configure Steam;
    a display-manager Gamescope session is a sharper console or HTPC posture.
  - How: keep the existing Steam profile, but introduce a separate option for
    session mode before adding more settings. A small shape such as
    `theorem.nixos.gaming.steam.session = "desktop" | "gamescope"` is enough if
    it avoids a large profile framework.
  - Achieves: normal desktop Steam does not quietly become an HTPC session, and
    HTPC work has a clear place to attach.
  - Validation: `programs.steam.gamescopeSession.enable` is false in desktop
    mode and true only when the host explicitly selects Gamescope session mode.

- [ ] Add Proton-GE as a Steam compatibility option.
  - Why: Proton-GE is a common compatibility substrate, but it should be visible
    and reversible.
  - How: add `programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ]`
    behind a Steam sub-option such as
    `theorem.nixos.gaming.steam.protonGe.enable`. Decide whether it defaults on
    with Steam or remains explicit; record the choice in the option
    description.
  - Achieves: Proton-GE availability without a user-managed hidden path.
  - Validation: evaluate `programs.steam.extraCompatPackages`, dry-build, then
    confirm Steam sees the compatibility tool after activation.

- [ ] Move host-level Wine staging into a named mechanism or user profile.
  - Why: `wineWow64Packages.staging` currently lives directly in
    `hosts/solanine/profiles.nix`, which hides whether it is system substrate,
    Vicky's workflow, or a game-specific requirement.
  - How: decide whether Wine staging belongs in a reusable gaming module, a Home
    launcher module, or `users/vicky/profiles/gaming.nix`. If it is kept at
    system scope, explain why.
  - Achieves: Wine does not linger as unexplained global package mass.
  - Validation: package still builds, any launcher depending on Wine still
    starts, and Solanine's package inventory shows the owner.

## Phase 3: Observability And Launchers

- [ ] Add MangoHud tooling without forcing overlays globally.
  - Why: MangoHud is the simplest measurement bench for gaming changes, but a
    global overlay can disturb normal application launches.
  - How: add a small NixOS package option for `pkgs.mangohud` and optionally
    `pkgs.goverlay`. Put per-user MangoHud configuration in a Home module or
    user profile if this repo needs it.
  - Achieves: benchmarking tools are available without turning every game into a
    measurement run.
  - Validation: `mangohud --version` runs after activation, and a selected game
    can display the overlay or write a log when launched with explicit MangoHud
    environment.

- [ ] Keep launcher applications explicit and mostly user-owned.
  - Why: Lutris, Heroic, Bottles, ProtonUp-Qt, and vkBasalt are useful, but they
    are optional applications and often carry per-user state.
  - How: create focused Home modules or Vicky profile selections before adding
    them to system packages. Use system modules only for root-owned integration
    they truly require.
  - Achieves: a second user can enable Steam without inheriting Vicky's launcher
    drawer or Wine prefix layout.
  - Validation: standalone `homeModules.shared` still passes
    `checks/home-shared-boundary.nix`, and package selections are visible in
    the relevant user profile.

- [ ] Decide the Aurora Toolset launcher path for Neverwinter Nights.
  - Why: this is already named in `docs/TODO.md`; a half-declared launcher can
    write toolset state into the wrong prefix or point at the wrong Steam
    install.
  - How: decide whether the launcher belongs in `modules/home/gaming/nwn.nix`
    or a package wrapper. Name executable, working directory, Wine or Proton
    environment, icon, and persistence assumptions.
  - Achieves: NWN tooling becomes a repairable game-specific mechanism rather
    than a private workaround.
  - Validation: launcher appears where expected, starts the toolset, writes
    state only to declared locations, and survives an impermanence reboot test
    if persistence is enabled.

## Phase 4: Gamescope, HTPC, And Controller-First Work

- [ ] Add a Gamescope module only after the Steam session split is settled.
  - Why: Gamescope can be nested, used as a Steam display-manager session, or
    used as a console-like shell. Those are different workflows with different
    breakage.
  - How: expose `programs.gamescope.enable`, `programs.gamescope.capSysNice`,
    and selected `programs.gamescope.args` through small options. Keep
    `capSysNice` disabled unless the host accepts the capability surface.
  - Achieves: Gamescope is available for frame pacing without broad capability
    grants by accident.
  - Validation: desktop mode can launch Steam normally; Gamescope session mode
    appears in the display manager only when selected; nested Gamescope failures
    are documented rather than hidden.

- [ ] Design an HTPC profile as a host posture, not a default.
  - Why: SteamOS-style UX is valuable for a living-room machine but invasive on
    a normal desktop.
  - How: add only the pieces required for an HTPC host: Steam Gamescope session,
    optional controller-oriented tools, and display-manager integration. Keep
    auto-login as a separate explicit host decision.
  - Achieves: a future media-room host can select a console rite without
    changing workstation behavior.
  - Validation: build a VM or test generation where the session appears,
    normal TTY recovery still exists, and rollback can return to desktop mode.

- [ ] Keep handheld support research-only until a handheld host exists.
  - Why: handheld daemons, inputplumber-style stacks, Decky-like tools, and
    device quirks are hardware-specific.
  - How: record candidate packages and NixOS modules, but do not enable
    services on Solanine unless the host actually owns that device class.
  - Achieves: desktop systems do not inherit irrelevant input daemons or
    controller remapping authority.
  - Validation: open a separate host-specific task when real handheld hardware
    is present.

## Phase 5: Kernel And Performance Experiments

- [ ] Decide whether a gaming kernel option is worth adding.
  - Why: `modules/nixos/base/boot.nix` already sets the host kernel with a
    normal override point, and Solanine currently evaluates to kernel `7.0.10`.
    A theorem option is useful only if it coordinates a real gaming posture.
  - How: compare direct host assignment against a small enum such as
    `"default" | "latest" | "zen"`. Prefer direct native NixOS options if the
    wrapper does not add clarity.
  - Achieves: kernel selection stays legible and avoids a decorative option
    layer.
  - Validation: targeted eval shows the selected `boot.kernelPackages`, then a
    dry build proves out-of-tree modules and graphics still build.

- [ ] Treat CachyOS kernels as an external supply-chain experiment.
  - Why: a CachyOS kernel flake may improve latency or responsiveness, but it
    changes kernel provenance, cache behavior, module compatibility, and
    rollback risk.
  - How: research the flake input, overlay choice, cache availability, kernel
    variants, build cost, and rollback plan. Do not add it to the normal
    profile. Prefer a specialization or disposable host trial first.
  - Achieves: performance experimentation without silently replacing the system
    kernel.
  - Validation: the experiment builds, boots, reports the expected kernel,
    launches Steam and a Proton game, runs the hardening diagnostics expected
    for the host, and can roll back to the normal generation.

- [ ] Keep Mesa-git, AMDVLK, USB polling patches, and global compiler flags out
  of the baseline.
  - Why: these can improve specific games or devices, but they increase rebuild
    churn, reduce binary-cache usefulness, or regress unrelated workloads.
  - How: treat each as a separate host experiment with a measured target. Do not
    add whole-system `-march=native`, broad overlays, or random patch stacking.
  - Achieves: the repo remains reproducible and cache-friendly by default.
  - Validation: each experiment names the game or hardware it helps, the
    before/after measurement, and the exact rollback path.

- [ ] Gate AMD p-state and low-latency kernel parameters behind host evidence.
  - Why: Solanine has its own AMDGPU freeze ledger, and boot parameters can make
    hardware failures harder to interpret.
  - How: test one parameter at a time, record it in the AMDGPU or gaming
    performance notes, and avoid mixing kernel, Mesa, compositor, and power
    changes in one generation.
  - Achieves: performance tuning does not muddy hardware diagnosis.
  - Validation: inspect `/proc/cmdline`, confirm the expected driver state, run
    the same benchmark before and after, and keep a clean rollback generation.

## Phase 6: Persistence, State, And Recovery

- [ ] Audit Steam persistence on impermanent hosts.
  - Why: `.local/share/Steam` may not cover every Steam, shader cache,
    compatdata, screenshot, or library path an operator expects to survive.
  - How: after Steam has run on an impermanent generation, inspect actual state
    paths and decide which ones belong in Home persistence. Avoid persisting
    broad paths such as `~/Games` or all of `.config` unless a user profile
    explicitly accepts that state.
  - Achieves: game libraries and compatibility data survive where intended
    without making the home directory sticky by accident.
  - Validation: install or launch a small game, reboot through impermanence,
    confirm expected state remains, and confirm unrelated test files are wiped.

- [ ] Keep Wine and launcher prefixes out of undeclared state.
  - Why: Lutris, Bottles, Heroic, ProtonUp-Qt, and custom Wine tools can create
    large mutable prefixes outside Steam's library.
  - How: for each selected launcher, declare whether its prefixes are
    persistent, disposable, backed up, or intentionally user-managed outside the
    system theorem.
  - Achieves: rollback does not surprise the operator by deleting or preserving
    the wrong game state.
  - Validation: create one controlled prefix, reboot or rebuild, and verify the
    declared state behavior.

- [ ] Document rollback for gaming experiments beside the mechanism.
  - Why: NixOS generation rollback does not roll back user data, Steam shader
    caches, Wine prefixes, or game saves.
  - How: in `docs/gaming-performance.md`, separate system rollback from user
    state recovery. Name any backup or persistence assumptions.
  - Achieves: the operator knows which parts of an experiment are reversible.
  - Validation: perform at least one build-only or test-generation rollback
    before switching a sharp profile permanently.

## Phase 7: Validation Rites

Use these before switching a host that changes gaming behavior. Run commands in
the local NixOS checkout for the target host, or adapt the host name if the work
is for another machine.

- [ ] Verify current option surfaces.
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.programs.steam --apply 'opts: builtins.attrNames opts'`
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.programs.gamescope --apply 'opts: builtins.attrNames opts'`
  - Command: `nix eval --json .#nixosConfigurations.solanine.options.programs.gamemode --apply 'opts: builtins.attrNames opts'`
  - Expected: Steam includes `extraCompatPackages` and `gamescopeSession`;
    Gamescope includes `capSysNice`; GameMode includes `enableRenice` and
    `settings`.

- [ ] Verify theorem state.
  - Command: `nix eval --json .#nixosConfigurations.solanine.config.theorem.nixos --apply 'nixos: { gaming = builtins.attrNames nixos.gaming; desktop = builtins.attrNames nixos.desktop; security = builtins.attrNames nixos.security; }'`
  - Expected: gaming mechanisms are visible under `theorem.nixos.gaming`, and
    desktop/security mechanisms still expose their expected categories.

- [ ] Run repository checks.
  - Command: `nix flake check`
  - Expected: the flake evaluates, including `checks/home-shared-boundary.nix`.

- [ ] Dry-build the target host before activation.
  - Command: `nixos-rebuild dry-build --flake .#solanine`
  - Expected: the host builds without switching, giving the operator a clean
    failure point before activation.

- [ ] Run runtime checks after activation.
  - Steam launches under the selected desktop session.
  - A Proton game launches with the selected compatibility tool.
  - `vulkaninfo --summary` or equivalent confirms the expected GPU driver and
    32-bit Vulkan support where practical.
  - `gamemoderun true` succeeds.
  - MangoHud overlay or logging works only when explicitly requested.
  - Gamescope session appears in the display manager only when enabled.
  - Steam Remote Play, dedicated server discovery, and local network transfers
    keep firewall ports closed unless the host explicitly opened them.
  - Rollback generation remains visible in the bootloader or through the normal
    NixOS rollback path.

## Deferred Until A Host Requires Them

- CachyOS or other externally supplied kernels.
- Mesa-git or broad graphics overlays.
- Whole-system compiler flags, `-march=native`, AutoFDO, Propeller, or
  ThinLTO outside a scoped kernel experiment.
- Handheld daemon stacks, Decky-like tools, and handheld controller services.
- Auto-login, kiosk mode, or forced Steam Big Picture startup.
- Flatpak-first gaming stack.
- USB polling patches, device-specific controller patches, or wheel support.
- Hardened kernel selection for gaming hosts before the compatibility matrix
  proves Steam, launchers, browsers, Flatpak, containers, and graphics drivers
  can tolerate it.

## Suggested Implementation Order

1. Write `docs/gaming-performance.md` and update
   `docs/hardening-compatibility.md`.
2. Repair GameMode and Steam option surfaces in the existing gaming modules.
3. Add Proton-GE and MangoHud as measured, reversible substrate.
4. Move launcher and Wine choices into their proper Home or system boundary.
5. Split Gamescope session mode from ordinary desktop Steam.
6. Run Solanine evals, `nix flake check`, and a dry build.
7. Only after the baseline proves stable, open separate experiments for kernel,
   HTPC, or handheld work.
