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
- Progress: shared Home base modules that follow NixOS state now tolerate
  standalone Home evaluation when `osConfig` is absent. XDG directories, fonts,
  Distrobox, Steam persistence, and Home persistence all default to inert or
  user-selected behavior outside the system theorem instead of dereferencing a
  missing NixOS configuration.
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
- Continue the option-boundary pass before adding another user: Plasma layout
  still needs the same calibration that editors, Codex CLI policy, GIMP,
  Spicetify, ripgrep, nix-index, Discord autostart, Home SSH, Firefox search
  defaults, KeePassXC posture, Ghostty/Zellij key ownership, and shell aliases
  now have.
- Completed: user SSH identity restoration no longer depends on the system
  OpenSSH service. The Home SSH module restores per-user SOPS-backed keys for
  outbound SSH and Git signing, while the host SOPS binding exposes user SSH
  secrets independently of `theorem.nixos.base.ssh.enable`. The NixOS SSH module
  continues to own `sshd`, host keys, firewall exposure, and inbound access.
- Completed: Git now consumes the Home SSH identity through
  `theorem.home.shell.git.sshSigning`, which defaults to enabled when
  `theorem.home.base.ssh.enable` is selected. User Git files keep personal name
  and email only, while shared commit-signing mechanics stay in the reusable Git
  module. Keep agent ownership singular, and avoid making Git imply `sshd`.
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
- Completed: shell aliases now pass through `theorem.home.shell.shell.aliases`,
  `extraAliases`, `nixosAliases`, and `elevationAlias`. Standalone Home flakes
  no longer inherit host-repair aliases by accident, and the `please` retry
  alias follows `run0` when the active NixOS elevation theorem selects it.
- Completed: `modules/home/shell/shell.nix` now defaults the shell baseline on,
  gates NixOS `nh` aliases on `osConfig.programs.nh.enable`, derives the alias
  flake target from `programs.nh.flake` or `repository.path`, provides `nr` for
  `nh os build`, and implements `please` as a Bash function that replays the
  previous command through the selected elevation command.
- Future shell UX research belongs in the ledger, not as an in-code TODO:
  ble.sh previously broke multiple shell integrations, but lightweight command
  suggestions or highlighting may be worth revisiting behind a separate option
  after Bash, Atuin, Carapace, Direnv, FZF, Zellij, and editor-embedded
  terminals are tested together.
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
- Progress: central stewardship modules now carry top-of-file purpose blocks:
  `lib/mkSystem.nix`, `modules/nixos/base/users.nix`,
  `modules/nixos/base/networking.nix`,
  `modules/nixos/base/nix-trusted-users.nix`,
  `modules/nixos/base/ssh.nix`, `modules/nixos/base/boot.nix`,
  `modules/nixos/base/locale.nix`, `modules/nixos/base/packages.nix`,
  `modules/nixos/virtualisation/podman.nix`,
  `modules/nixos/security/sudo.nix`, `modules/nixos/security/run0.nix`,
  `modules/home/base/persistence.nix`, `modules/home/base/xdg.nix`,
  `modules/home/base/fonts.nix`, `modules/home/base/virtualization.nix`, and
  `modules/home/gaming/steam.nix`. `modules/home/shell/shell.nix` and
  `modules/home/web/ungoogled-chromium.nix` also now carry their local doctrine
  and no longer use inline TODO/FIXME notes for known follow-up work. The next
  pass should continue module by module, placing the doctrine beside the
  mechanism instead of burying it in a distant checklist.
- Completed: every `.nix` module under `modules/` now has a top-of-file purpose
  block or an equivalent boundary note near the module entry. This does not end
  documentation stewardship: option descriptions, directory READMEs, and host
  notes still need to stay current when mechanisms change, but the broad module
  map is now carried beside the mechanisms themselves.

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
  - Completed: [`docs/threat-model.md`](./threat-model.md) names the baseline
    local risks before broad hardening work: physical theft, hostile networks,
    browser compromise, leaked secrets, broken rebuild paths, and accidental
    operator damage. Use it as the gate before importing any sharp security
    profile.
  - Completed: `modules/nixos/base/users.nix` keeps
    `users.mutableUsers = false` in the base user doctrine. Every login-capable
    account selected by Solanine receives a SOPS-backed password hash, while
    `guest` remains deliberately passwordless and outside the Home Manager
    persistence surface until a host names a guest workflow.
  - Progress: XDG directory posture is part of the Home baseline review.
    `modules/home/base/xdg.nix` declares ordinary directories such as
    `Documents`, `Downloads`, and `Projects`, and now defaults off cleanly for
    standalone Home flakes with no system graphics profile.
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
    Progress: the hardening theorem now exposes
    `theorem.nixos.security.hardening.networkManagerMacRandomization.enable`
    as an opt-in NetworkManager posture. It keeps Wi-Fi scan randomization
    visible, defaults Wi-Fi connections to `stable-ssid`, preserves wired
    Ethernet identity by default, and leaves current hosts unchanged until a
    travel or untrusted-network profile selects the rite.
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
  - Progress: `modules/home/web/ungoogled-chromium.nix` now names Chromium as a
    fallback and web-development browser, and intentionally avoids
    `home.persistence` hooks so impermanent hosts discard its profile unless a
    user chooses state elsewhere.
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
    integration blur those boundaries without a reason.
  - Treat Xwayland, desktop portals, and screenshot/screencast protocols as
    desktop threat-model topics. Plasma and Wayland are useful defaults, but
    each desktop profile should name what it exposes.
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

- Completed: `admin` now keeps its minimal Home Manager repair profile while
  explicitly disabling `theorem.home.base.persistence.enable`; `guest` still has
  `home.enable = false`, so it receives no Home Manager persistence surface.
  `users/README.md` documents the boundary: the system may prepare an empty
  `/nix/persist/home/<user>` repair cradle for selected Home Manager users, but
  files are not persisted unless that user's Home profile declares
  `home.persistence` entries.

## Solanine AMDGPU Plasma Freezes

Solanine still experiences the well-documented "flip_done" freeze despite some
kernel module workarounds being applied. There is also a real world workaround
where the user unplugs the monitor cable from the back of the PC, plugs it back
in, and hits a key a few times to wake the monitor. This is documented as working
during two such freeze cases.

The detailed repair ledger now lives in
[`docs/solanine-amdgpu-freezes.md`](./solanine-amdgpu-freezes.md). Keep future
evidence, tried parameters, rollback notes, and capture commands there so the
mechanism has one memory.

What has been tried so far:
- Kernel versions 6.12, Default LTS kernel 6.18, and now the latest unstable.

Documentation checked before pursuing:

- ArchWiki records `amdgpu.dcdebugmask=0x10` or `amdgpu.dcdebugmask=0x12` as
  workarounds for frozen or unresponsive AMDGPU displays with `flip_done timed
  out`.
- An AMD GFX patch thread from February 2026 tracks an upstream race that can
  produce intermittent `flip_done` timeouts on KDE Plasma Wayland since kernel
  6.12, so local parameters should remain reversible trials until the fixed
  kernel path is known.

Progress: Solanine now tests the next host-scoped workaround in
`hosts/solanine/hardware.nix`: `amdgpu.dcdebugmask=0x52` replaces the
insufficient `0x12`, keeping PSR and stutter disabled while also disabling AMD
Display Core multi-plane offloading after the June 4, 2026 `10:44` freeze
showed a plane commit timeout. `amdgpu.runpm=0` keeps the desktop GPU out of
runtime power-down while diagnosing the "no outputs" freeze. This is not proven
until the host boots the generation and survives normal Plasma uptime. If idle
power or thermals become the sharper failure mode, remove `amdgpu.runpm=0`
first; if the newest display workaround regresses behavior, return `0x52` to
`0x12`.

Validation: boot Solanine, confirm `/proc/cmdline` contains
`amdgpu.dcdebugmask=0x52` and `amdgpu.runpm=0`, use the normal Plasma Wayland
session through the workflows that previously froze, and review
`journalctl -b -k | rg 'flip_done|commit wait|amdgpu_dm'`. If the freeze
returns, capture `sudo dmesg` and
`journalctl --user-unit plasma-kwin_wayland --boot 0` before trying a kernel,
Mesa, firmware, cable/port, or VRR-focused trial.

Below is some of the journalctl output.

```
Jun 04 08:55:30 solanine kdeconnectd[3911]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine kactivitymanagerd[3775]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine polkit-kde-authentication-agent-1[3779]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine baloorunner[10023]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine baloo_file_extractor[13063]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine plasmashell[3748]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine org_kde_powerdevil[3780]: There are no outputs - creating placeholder screen
Jun 04 08:55:30 solanine systemd[3422]: Started dbus-:1.2-org.kde.KSplash@1.service.
Jun 04 08:55:32 solanine pipewire-pulse[3878]: mod.protocol-pulse: setsockopt(SO_PRIORITY) failed: Bad file descriptor
Jun 04 08:55:32 solanine pipewire-pulse[3878]: mod.protocol-pulse: client 0x5ba79e7fd760: no peercred: Bad file descriptor
Jun 04 08:55:32 solanine plasmashell[3748]: qrc:/qt/qml/plasma/applet/org/kde/plasma/notifications/global/Globals.qml:575:17: Unable to assign QString to int
Jun 04 08:55:32 solanine kded6[3701]: Failed to notify "Created too many similar notifications in quick succession"
Jun 04 08:55:43 solanine kernel: amdgpu 0000:03:00.0: [drm] *ERROR* flip_done timed out
Jun 04 08:55:43 solanine kernel: amdgpu 0000:03:00.0: [drm] *ERROR* [CRTC:363:crtc-0] commit wait timed out
Jun 04 08:55:51 solanine discord[3908]: 08:55:51.727 › The resource https://discord.com/assets/ce3b8055f5114434.woff2 was preloaded using link preload but not used within a few seconds from the window's load >
Jun 04 08:55:51 solanine discord[3908]: 08:55:51.727 › The resource https://discord.com/assets/cb2006dbced0e246.woff2 was preloaded using link preload but not used within a few seconds from the window's load >
Jun 04 08:55:51 solanine discord[3908]: 08:55:51.728 › The resource https://discord.com/assets/7a6a566c2e88a35d.woff2 was preloaded using link preload but not used within a few seconds from the window's load >
Jun 04 08:55:51 solanine discord[3908]: 08:55:51.728 › The resource https://discord.com/assets/e52f0cba712e2fb4.woff2 was preloaded using link preload but not used within a few seconds from the window's load >
Jun 04 08:55:51 solanine discord[3908]: 08:55:51.728 › The resource https://discord.com/assets/dd24010f3cf7def7.woff2 was preloaded using link preload but not used within a few seconds from the window's load >
Jun 04 08:55:53 solanine kernel: amdgpu 0000:03:00.0: [drm] *ERROR* flip_done timed out
Jun 04 08:55:53 solanine kernel: amdgpu 0000:03:00.0: [drm] *ERROR* [PLANE:360:plane-6] commit wait timed out
Jun 04 08:55:54 solanine kernel: ------------[ cut here ]------------
Jun 04 08:55:54 solanine kernel: WARNING: drivers/gpu/drm/amd/amdgpu/../display/amdgpu_dm/amdgpu_dm.c:9576 at amdgpu_dm_atomic_commit_tail+0x3635/0x3690 [amdgpu], CPU#2: kworker/2:1H/629
Jun 04 08:55:54 solanine kernel: Modules linked in: ccm rfcomm snd_seq_dummy snd_hrtimer snd_seq snd_seq_device af_packet cmac algif_hash algif_skcipher af_alg bnep nls_iso8859_1 rtw89_8852be nls_cp437 r8169 >
Jun 04 08:55:54 solanine kernel:  video hid_generic mt792x_lib mt76_connac_lib tiny_power_button rtc_cmos mt76_usb mt76 gpio_amdpt wmi gpio_generic button mac80211 btusb btrtl btintel btmtk btbcm cfg80211 blu>
Jun 04 08:55:54 solanine kernel: CPU: 2 UID: 0 PID: 629 Comm: kworker/2:1H Not tainted 7.0.10 #1-NixOS PREEMPT(lazy)
Jun 04 08:55:54 solanine kernel: Hardware name: ASUS System Product Name/PRIME B650M-A WIFI II, BIOS 3263 06/09/2025
Jun 04 08:55:54 solanine kernel: Workqueue: events_highpri dm_irq_work_func [amdgpu]
Jun 04 08:55:54 solanine kernel: RIP: 0010:amdgpu_dm_atomic_commit_tail+0x3635/0x3690 [amdgpu]
Jun 04 08:55:54 solanine kernel: Code: ff ff 90 0f 0b 49 8d 84 24 40 5b 04 00 c6 85 18 fe ff ff 00 48 89 85 20 fe ff ff e9 56 d0 ff ff 90 0f 0b 90 e9 9f d0 ff ff 90 <0f> 0b 90 e9 fc f7 ff ff 48 c7 85 18 fe ff>
Jun 04 08:55:54 solanine kernel: RSP: 0018:ffffd39041e67ac8 EFLAGS: 00010086
Jun 04 08:55:54 solanine kernel: RAX: 0000000000000001 RBX: 0000000000000296 RCX: ffff8e560591f118
Jun 04 08:55:54 solanine kernel: RDX: 0000000000000001 RSI: 0000000000000286 RDI: ffff8e563c480178
Jun 04 08:55:54 solanine kernel: RBP: ffffd39041e67d40 R08: ffffd39041e679bc R09: 0000000000000000
Jun 04 08:55:54 solanine kernel: R10: ffff8e5606d52e00 R11: ffffd39041e67a2c R12: ffff8e560591f118
Jun 04 08:55:54 solanine kernel: R13: 0000000000000000 R14: ffff8e56118c7600 R15: ffff8e560591f000
Jun 04 08:55:54 solanine kernel: FS:  0000000000000000(0000) GS:ffff8e5db7bdd000(0000) knlGS:0000000000000000
Jun 04 08:55:54 solanine kernel: CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
Jun 04 08:55:54 solanine kernel: CR2: 00003be40573e3fc CR3: 00000002ec224000 CR4: 0000000000f50ef0
Jun 04 08:55:54 solanine kernel: PKRU: 55555554
Jun 04 08:55:54 solanine kernel: Call Trace:
Jun 04 08:55:54 solanine kernel:  <TASK>
Jun 04 08:55:54 solanine kernel:  commit_tail+0xd1/0x160
Jun 04 08:55:54 solanine kernel:  drm_atomic_helper_commit+0x13c/0x180
lines 919-962/1000 97%
```
