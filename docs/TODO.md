# TODO

This is the repair ledger for work that should become configuration, not a pile
of hopeful comments. Each item should name the mechanism, the failure mode, and
the validation rite that proves it still holds.

NOTE: When completing a task, fold its relevant documentation into the correct
place. Use `README.md` and `docs/` as readable sources for what purpose every
change serves. Documentation maintenance is critical for keeping the repo
as understandable as possible for newer maintainers.

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
  and other repository-local repair surfaces. Do not widen application-control
  groups to guests or outside accounts just because the name changes.
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
- Current state: shared Home base modules that follow NixOS state tolerate
  standalone Home evaluation when `osConfig` is absent. XDG directories, fonts,
  Distrobox, Steam persistence, and Home persistence all default to inert or
  user-selected behavior outside the system theorem instead of dereferencing a
  missing NixOS configuration.
- Boundary record: `users/README.md` now names the two-lane Home doctrine, and
  `lib/mkSystem.nix` remains the system-managed Home import gate. Do not add
  discovery of user-owned Home flakes here; design an exported baseline that
  personal repositories can import under their own authority.
- Exported baseline: `homeModules.shared` now gives user-owned Home flakes a
  reusable entry point for this repository's Home modules without selecting a
  host, login account, SOPS identity, or Vicky profile. Optional persistence and
  Plasma hooks stay quiet unless their option providers are present; selecting
  those substrates without the provider fails with a clear assertion.
- External-user posture: this flake should be safe for other users to consume
  without inheriting Vicky's private working surface. Vicky's Home Manager
  theorem now belongs in `/home/vicky/Repositories/nix-home`, which should be
  treated as a user-owned flake consuming this repository's exported Home
  baseline rather than as configuration hidden inside the shared system flake.
- Vicky Home migration rite:
  1. In `/home/vicky/Repositories/nix-home`, declare a Home Manager flake that
     imports this repository's `homeModules.shared` entry point, first through a
     local path during repair and later through the public repository URL that
     external users will see.
  2. Move Vicky-specific Home imports in small, reviewable slices from
     `users/vicky/` into the personal Home flake: identity, Git posture,
     SSH host aliases, desktop preferences, editor settings, shell habits,
     application selections, and other private workshop calibration.
  3. Leave system authority in this repository: login account creation, groups,
     persistence substrate, SOPS integration, service-owned permissions, login
     shell choices, and any host declaration that intentionally trusts
     user-writable Home code.
  4. If a host still evaluates Vicky's Home through `nixos-rebuild` during the
     transition, declare the trust gate explicitly as
     `/home/vicky/Repositories/nix-home`; do not add auto-discovery of home
     flakes or imports from arbitrary user-writable paths.
  5. Validate both sides before activation: keep this repository's
     `checks/home-shared-boundary.nix` passing, run `nix flake check` here, run
     the corresponding check or activation-package build in
     `/home/vicky/Repositories/nix-home`, and only then activate Vicky's Home
     from the user-owned repository.
  6. Once Vicky's Home activates from the personal repository, remove or narrow
     any remaining Vicky-only Home imports from this shared flake so external
     users see reusable modules, defaults, and examples rather than one
     operator's private workshop.
- Validation: `checks/home-shared-boundary.nix` simulates a non-repository Home
  profile through `homeModules.shared`, without Vicky profile imports or a NixOS
  `osConfig`. Separately prove that a personal Home flake can build or activate
  from a user's own directory without write access to `/nix/nixos`, and that
  system rebuilds do not import user-writable Nix unless the host explicitly
  declares that trust gate.

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
  tested on a host. The profile now has a configurable sudo compatibility alias
  and intentionally keeps run0 password-gated; the working passwordless knob is
  broader systemd unit-management authority, not a narrow NixOS rebuild cache.
  Prove login, elevation, rebuild, and rollback before making it a default.

## Home Module Boundary

- Keep reusable Home Manager modules focused on mechanisms and broadly useful
  defaults. User modules should carry themes, editor posture, shell habits,
  autostart choices, plugin-bearing packages, and language stacks that are only
  true for one operator.
- Continue the option-boundary pass before adding another user by checking each
  reusable Home module for personal posture before it becomes another user's
  inheritance.
- Repaired boundary map: `users/README.md` records that
  `users/vicky/profiles.nix` is only an import coordinator, while focused files
  under `users/vicky/profiles/` own Vicky's desktop, Plasma, editor, shell, web,
  and gaming posture. `modules/home/README.md` records the shared Home boundary;
  use those documents before opening another user-profile split.
- Repaired identity map: `modules/home/base/ssh.nix` owns outbound user SSH
  identity restoration, `modules/home/shell/git.nix` owns SSH commit-signing
  mechanics, and `modules/nixos/base/ssh.nix` owns inbound `sshd`, host keys,
  firewall exposure, and remote-login posture. Keep those identities separate
  when adding future agent, GPG, or hardware-token work.
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
- Future shell UX research belongs in the ledger, not as an in-code TODO:
  ble.sh previously broke multiple shell integrations, but lightweight command
  suggestions or highlighting may be worth revisiting behind a separate option
  after Bash, Atuin, Carapace, Direnv, FZF, Zellij, and editor-embedded
  terminals are tested together.
- Neverwinter Nights still needs an Aurora Toolset launcher decision. Decide
  whether the launcher belongs in the NWN Home module or in a package wrapper,
  then name the executable, working directory, Wine or Proton environment, icon,
  and persistence assumptions explicitly. The failure mode is worse than a
  missing menu entry: a half-declared launcher can write toolset state into an
  unmanaged prefix or point at the wrong game install.
- Validation: keep `checks/home-shared-boundary.nix` passing. It should build a
  plain synthetic Home profile from the shared module tree, not Vicky's editor
  theme, VS Code workflow, GIMP plugin build, Spotify extensions, Discord
  autostart, command-not-found hook, or repository-specific ripgrep posture.

## In-File documentation

- Keep module purpose blocks, option descriptions, directory READMEs, and host
  notes current when mechanisms change. The broad map now lives in
  `modules/nixos/README.md`, `modules/home/README.md`, and top-of-file module
  purpose blocks; do not re-open a generic documentation TODO unless a specific
  mechanism has drifted from its local explanation.
- Validation: when changing a mechanism, read the adjacent purpose block and
  the relevant directory README after the patch. The text should still name what
  the mechanism protects, what can break, and which command or boot test proves
  it.

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

- Treat hardening as calibrated stewardship, not as a pile of switches. Start
  each security mechanism with the local threat it answers, the workflow it can
  break, the recovery path, and the command or boot test that proves it still
  serves the host. This matches the direction of
  [`docs/TODO-nixos-hardening.md`](./TODO-nixos-hardening.md) and
  [`docs/hardening-compatibility.md`](./hardening-compatibility.md): sharp
  options belong behind host signals, overrides, and rollback.
- Fold the external hardening notes below into local mechanisms only when they
  survive this repository's doctrine: explicit enablement, least privilege,
  declared persistence, secret material outside the Nix store, and no hidden
  dependence on one user's working surface. The useful question is not "can this
  be enabled?" but "what does this protect, what does it cost, and how does a
  tired operator reverse it?"
- Baseline system hardening queue:
  - Convert any remaining implicit security assumptions into named checks:
    firewall posture, user account mutability, root-login avoidance, log review,
    update cadence, and password-manager expectations.
  - Use [`docs/threat-model.md`](./threat-model.md) as the gate before importing
    any sharp security profile. Local risks, mutable-user doctrine, and XDG
    baseline posture now have permanent homes in `docs/threat-model.md`,
    `modules/nixos/base/users.nix`, and `modules/home/base/xdg.nix`; update
    those mechanisms directly when the doctrine changes.
  - Compare these against existing modules before adding new options. If native
    NixOS options already describe the behavior cleanly, document the expected
    host setting instead of wrapping it.
  - Validation: targeted `nix eval`, `nix flake check`, dry build, and an
    activation test that includes login, elevation, network recovery, and
    rollback.
- Networking and DNS queue:
  - Keep the current firewall doctrine explicit. Future encrypted DNS,
    dnscrypt-proxy, nftables, OpenSnitch, Tailscale, or MAC-randomization work
    should be separate mechanisms with clear failure modes for captive portals,
    VPNs, local discovery, split DNS, and emergency remote access.
  - If adding `dnscrypt-proxy`, treat it as a DNS-routing mechanism rather than
    a standalone privacy guarantee. It may point system DNS at localhost, use
    resolver and relay lists with cached state, require DNSSEC/no-log/no-filter
    choices, and optionally consume blocklists. Frequently changing blocklist
    inputs can produce flake hash churn or `NarHash` mismatches, so blocklist
    updates need the same lockfile discipline as any other input.
  - Browser DNS must be reviewed separately from system DNS. A browser configured
    for strict DoH can bypass or contradict the local resolver; a browser left
    at vendor defaults can leak around a carefully built system resolver.
  - If enforcing DNS with nftables, gate it behind a tested module. Blocking all
    outbound port 53 or 853 except a local resolver process can protect against
    leaks, but it can also break captive portals, VPN bootstrap, Tailscale DNS,
    local lab devices, and emergency troubleshooting.
  - Tailscale should be its own profile with explicit DNS behavior. Trusting
    `tailscale0`, accepting MagicDNS, using exit nodes, or setting
    `--accept-dns=false` are different choices; each affects name resolution and
    remote recovery differently.
  - MAC randomization belongs behind a travel or untrusted-network profile, not
    as an unexamined desktop default. NetworkManager can randomize scan and
    connection MACs, but home routers, allow-lists, and location-specific
    networks may interpret the host as a new device.
    The opt-in mechanism lives at
    `theorem.nixos.security.hardening.networkManagerMacRandomization.enable`;
    extend it only with travel or untrusted-network validation, not as base
    networking drift.
  - Do not collapse privacy tools into the base networking module. A workstation,
    a travel laptop, and a server have different network rites.
  - Validation: `ss -lnp` for local DNS listeners, `dig @127.0.0.1 example.com
    +short`, `journalctl -u dnscrypt-proxy2`, browser DNS inspection,
    LAN-discovery check where needed, `tailscale status` where selected, and a
    recovery path when name resolution fails.
- Browser and desktop privacy queue:
  - Keep native Firefox, ungoogled Chromium, Firejail, Flatpak, and portal
    choices comparable rather than fashionable. Browser sandbox strength,
    screen-sharing behavior, password-manager integration, downloads, and
    profile persistence all interact.
  - Name the browser goal before changing prefs: security, privacy, anonymity,
    or convenience. Standardized fingerprints such as Tor or Mullvad Browser
    serve anonymity but can break sites and invite CAPTCHAs; randomized
    fingerprints such as Brave's model reduce linkability but can still be
    correlated by accounts, IP ranges, behavior, and logs.
  - Keep extension count low. Every privileged browser extension increases
    attack surface and fingerprint uniqueness. Prefer built-in browser controls
    and one well-understood content blocker over a drawer full of small helpers.
  - If importing Arkenfox or STIG-like Firefox policy, treat it as a reviewed
    policy source, not a trusted include by default. Track upstream changes, put
    local overrides after imported `user.js` material when order matters, and
    test actual `about:config` values after activation.
  - Browser compartmentalization should be deliberate: one daily browser, one
    hardened or amnesic browser, and one anonymity browser are different tools.
    Do not let MIME defaults, XDG handlers, sync accounts, or password-manager
    integration blur those boundaries without a reason. (NOTE: Regarding MIME,
    it is safer to open "random links" in the hardened/amnesiac browser such as
    firejailed LibreWolf or perhaps Mullvad in the future. However, where
    concerns API calls, not using the daily browser can pose a convenience curb,
    preventing sign-ins to every day tools like Codex. Since the amnesiac
    browsers will never remember those logins, the distinction should be made
    clean and predictable. Random html file? Open in the amnesiac browser for
    security. API call to login tool? Goes to the daily driver browser. Etc.)
  - Treat Xwayland, desktop portals, and screenshot/screencast protocols as
    desktop threat-model topics. Plasma and Wayland are useful defaults, but
    each desktop profile should name what it exposes. Research exact Xwayland
    needs for all present hosts before tightening this path. Steam requires it,
    and some daily applications may still lack a stable Wayland route. The
    useful mechanism would derive Xwayland or portal support from explicit
    application needs, such as Discord screen sharing, instead of leaving those
    surfaces ambient.
  - Validation: browser sandbox diagnostics, fingerprint sanity checks such as
    Cover Your Tracks or Am I Unique without overfitting to them, portal
    screen-share test, download persistence check, password-manager workflow,
    declared search defaults, and profile restore.
- Secrets and identity queue:
  - Keep `sops-nix` as the repository's secret substrate. Secret files need
    creation rules before `sops edit`, declared runtime paths before rebuilds,
    and Git visibility before flakes can evaluate them.
  - Preserve the distinction between encryption strength and secret entropy.
    SOPS protects the file at rest, but a low-entropy cleartext secret, reused
    password, weak age key handling, or committed plaintext still defeats the
    rite. Secret review must look at the plaintext shape before encryption, not
    only at the encrypted file.
  - Keep `.sops.yaml` creation rules close to the file layout. When a new class
    of secret appears, add the rule first, then create the encrypted file from
    the repository root, then add it to Git before asking Nix to evaluate it.
  - Prefer Ed25519 SSH host keys where SOPS derives age recipients from host
    SSH material. RSA host keys may still exist for SSH compatibility, but they
    should not become the assumed decryption substrate.
  - Continue separating identity classes: SOPS age keys decrypt repository
    secrets; host SSH keys identify inbound servers; user SSH keys identify
    outbound users and Git signing. One name, one authority, one recovery rite.
  - Validation: `sops` decrypt/edit from the intended account, `nix eval` of
    declared secret paths, activation check that runtime files exist with the
    expected owner and mode, and a Git signing test for users that enable it.
- Agent and signing queue:
  - Keep the current OpenSSH-agent path as the default for SSH commit signing.
    If a future profile adds `gpg-agent` with SSH support, make it a separate
    option that replaces agent ownership instead of competing with
    `programs.ssh.startAgent`.
  - A GPG profile needs its own pinentry, `GPG_TTY`, agent socket, keygrip, and
    restart diagnostics. Missing pinentry often looks like a Git signing
    failure, not like a desktop integration problem, so the failure text should
    be documented beside the option.
  - Treat OpenPGP verification as "verify and inspect what was verified".
    Automation should not equate a valid cryptographic signature with the
    displayed payload being the intended payload after parsing, extraction, or
    mail-client handling.
  - Validation: `ssh-add -L`, matching `SSH_AUTH_SOCK`, `gpgconf --list-dirs
    agent-ssh-socket` for GPG-agent profiles, `gpg --card-status` for hardware
    token profiles, and a signed Git commit from the selected account.
- Secure boot and disk chain queue:
  - Treat lanzaboote, UEFI admin passwords, LUKS, initrd unlock, and Btrfs
    rollback as one boot-chain research area with several gates. Secure boot is
    not repair if it prevents the operator from booting a recovery generation.
  - Lanzaboote requires UEFI and systemd-boot posture before migration. The
    first pass should inspect `bootctl status`, install `sbctl` as a diagnostic
    tool, create or migrate keys outside the Nix store, force-disable
    `systemd-boot` only inside the Lanzaboote module, and point
    `boot.lanzaboote.pkiBundle` at the runtime key bundle.
  - Secure Boot without full-disk encryption only verifies part of the boot
    chain. It does not verify userspace in the Nix store after boot, and it does
    not by itself stop someone with firmware access from disabling the feature.
    UEFI admin password posture and LUKS belong in the same plan.
  - Validation: disposable-machine enrollment, `sbctl verify`, `sbctl status`,
    dbx presence check when enrolling vendor keys, reboot, rollback generation,
    recovery media, and a documented reset path before selecting it on the main
    host.
- Containers and sandboxing queue:
  - Keep Podman, Docker compatibility, Firejail, Flatpak, AppImage/FUSE, and
    browser sandboxes in the compatibility matrix. Many of these need user
    namespaces or SUID helpers; removing those globally can quietly break the
    exact containment tools meant to improve safety.
  - NixOS `containers.*` are useful for declarative service separation,
    disposable tests, and small localhost services, but they are not a full
    security boundary by default. A privileged root inside a weakly configured
    container can still become a host problem.
  - Prefer `ephemeral = true`, read-only bind mounts, narrow ports, and explicit
    state paths for simple service containers. If state must persist, name where
    it lives and how to remove it safely; container state under
    `/var/lib/nixos-containers` may need attribute cleanup before deletion.
  - For OCI containers built from local derivations, keep secrets in
    `environmentFiles`, avoid network pulls with `--pull=never` where using a
    locally built image, and use hardening flags such as `--cap-drop=ALL` and
    `--security-opt=no-new-privileges` when the workload can bear them.
  - Validation: rootless container run, Docker-socket authority check when
    enabled, wrapper inventory, Flatpak portal test, named application launch
    under its intended sandbox, `nixos-container status` for NixOS containers,
    service health inside the container, and host bind-mount permissions.
- Git and repository workflow queue:
  - Keep Git commit signing tied to declared user identity rather than copied
    per-user snippets. SSH signing now follows `theorem.home.base.ssh` through
    `theorem.home.shell.git.sshSigning`; future Git options should preserve that
    shared mechanism.
  - Keep Git as the configuration-history layer beside NixOS generations. A
    NixOS rollback changes the active system generation, not the flake files,
    service data, or user data that caused the next rebuild. Commit before risky
    experiments, review with `git diff`, and use revert/branch workflows for
    configuration repair instead of relying on bootloader rollback alone.
  - Preserve the current Git defaults that favor linear, inspectable repair:
    fast-forward-only pulls, explicit rebase workflow, shared safe-directory
    posture, and signed commits where the user has a restored SSH identity.
  - Research Jujutsu as a local workflow tool before integrating it into the
    flake. The first question is whether it improves repair and review without
    confusing repository stewardship, commit signing, or shared worktree
    permissions.
  - The JJ trial should use a disposable clone or a deliberate collocated
    workspace via `jj git init --colocate`. Record that JJ uses the working copy
    as a commit, has no Git index, stores bookmarks differently from Git
    branches, snapshots operations for undo, and can represent conflicts inside
    commits. These features may help repair work, but they also change the
    operator's habits at the exact place this repository needs discipline.
  - Do not add JJ aliases or packages globally until submodule behavior, large
    repository performance, Git signing, GitHub push/fetch, shared repository
    permissions, and fallback to ordinary Git have been tested.
  - Validation: signed commit, shared `/nix/nixos` write test for `admin` and
    daily operator, safe-directory behavior, and any JJ/Git interop check before
    adding packages or aliases.
- Nixpkgs and local package work queue:
  - Use the linked nixpkgs material to improve local package review, overlays,
    and derivation literacy. The local doctrine remains: recipes live under
    `pkgs/`, modules and profiles decide installation, and package-bearing
    changes go through [`docs/package-inventory.md`](./package-inventory.md).
  - Move fast-moving package feeds out of broad flake input doctrine when a
    narrower module or package wrapper can own the churn. Codex CLI,
    superpowers, NUR-backed browser choices, and any future nightly browser
    channel should not force unrelated operators to refresh the whole theorem
    just to receive frequent tool updates. The failure mode is lockfile churn
    becoming ordinary maintenance noise, hiding the updates that actually need
    review. Validation: prove the consuming module still evaluates, the package
    update path is explicit, and `nix flake check` plus the host dry build no
    longer change unrelated inputs for that tool.
  - Document a local-nixpkgs repair workflow before using one for production
    fixes: clone or worktree location, how the flake input is temporarily
    pointed at it, how overlays differ from direct package definitions, and how
    to prove the final host is no longer depending on an unreviewed local path.
  - Package definitions should keep source, lockfiles, runtime wrappers,
    metadata, and tests visible. For Rust packages, commit and use `Cargo.lock`
    when possible; for wrapped tools, name every runtime binary injected into
    `PATH` so the closure is not a surprise.
  - Overlay notes should explain `final` versus `prev`, when `callPackage` is
    enough, and when an overlay is too broad for a one-off local package.
  - Validation: package build, package inventory eval, unfree predicate check
    where relevant, `nix why-depends` for surprising closures, and dry build for
    any module that installs the package.

Research sources to revisit and distill when working a specific slice:
<https://saylesss88.github.io/nix/index.html>
<https://saylesss88.github.io/nix/hardening_networking.html>
<https://saylesss88.github.io/nix/browsing_security.html>
<https://saylesss88.github.io/installation/enc/sops-nix.html>
<https://saylesss88.github.io/nix/gpg-agent.html>
<https://saylesss88.github.io/installation/enc/lanzaboote.html>
<https://saylesss88.github.io/nixos_containers.html>
<https://saylesss88.github.io/vcs/git.html>
<https://saylesss88.github.io/vcs/jujutsu.html>
<https://saylesss88.github.io/vcs/practical_jj.html>
<https://github.com/jj-vcs/jj>
<https://saylesss88.github.io/Working_with_Nixpkgs_Locally_10.html>
<https://saylesss88.github.io/Package_Definitions_Explained_6.html>

## Additional Users

- Before promoting `guest` or another local account into a real working user,
  name the workflow, decide whether Home Manager is enabled, and declare only
  the persistence paths that should survive rollback. `users/README.md` carries
  the current account-boundary doctrine for `admin`, `guest`, and `vicky`.

## Solanine AMDGPU Plasma Freezes

The detailed repair ledger now lives in
[`docs/solanine-amdgpu-freezes.md`](./solanine-amdgpu-freezes.md). Keep future
evidence, tried parameters, rollback notes, and capture commands there so the
mechanism has one memory.
