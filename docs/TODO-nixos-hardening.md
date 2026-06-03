# NixOS Conservative Hardening TODO

Source guide: <https://saylesss88.github.io/nix/hardening_NixOS.html>

This is the hardening ledger for NixOS systems deployed from this repository.
The goal is not maximum suspicion at any cost. The goal is conservative
defaults: protect every host where the protection is low-risk, derive sharper
defaults from declared host capabilities, and keep dangerous rites behind clear
enablement and rollback paths.

Option paths named here were spot-checked against
`.#nixosConfigurations.solanine.options` on 2026-06-03. Re-verify each option
when implementation begins; NixOS option names are part of the mechanism, not
decoration.

## Default Doctrine

- [x] Build a `theorem.nixos.security.hardening` profile with explicit
  sub-options instead of scattering hardening across unrelated modules.
  - Why: hardening must be auditable as one posture while still allowing
    host-specific escape hatches.
  - How: create narrowly scoped modules under `modules/nixos/security/`, use
    `mkDefault` for conservative defaults, and require explicit host/profile
    opt-in for settings with known breakage.
  - Achieves: a common repair surface for all hosts, with every sharp edge named.
  - Validation: run `nix flake check`, targeted `nix eval` for the new theorem
    options, and `nixos-rebuild dry-build --flake .#solanine` before any switch.
  - Completed: `modules/nixos/security/hardening.nix` now provides an explicit
    opt-in profile, and `solanine` selects it in `hosts/solanine/profiles.nix`.
    The profile starts with low-risk kernel protections, coredump reduction,
    bounded local journald storage, logrotate, and an opt-in dbus-broker switch.

- [x] Maintain a hardening compatibility matrix.
  - Why: the guide repeatedly warns that settings can break Flatpak,
    Chromium-based browsers, Firefox-family browsers, containers, WireGuard,
    virtualization, NVIDIA or VirtualBox modules, screen sharing, USB input, and
    long-term logs.
  - How: document derived conditions such as "if Flatpak or Chromium exists,
    do not select the hardened kernel" and "if containers are enabled, do not
    disable unprivileged user namespaces globally."
  - Achieves: highest safe default per host instead of one brittle global
    hammer.
  - Validation: evaluate at least one desktop host, one headless/server profile,
    and one container-capable profile.
  - Completed: `docs/hardening-compatibility.md` records host signals, known
    breakage, gates before enablement, and forbidden shortcuts for the current
    hardening queue.

## Attack Surface And Package Hygiene

- [x] Keep software installation minimal and auditable.
  - Why: every installed service or package can carry vulnerabilities, and Linux
    desktop applications usually run with the full authority of the user.
  - How: keep packages in profiles that explain their need; prefer maintained
    packages; review package homepages for critical tools; avoid broad
    `environment.systemPackages` growth.
  - Achieves: smaller attack surface and easier package review.
  - Default posture: safe default. No package should become global without a
    reason.
  - Validation: add a package inventory check to the hardening review and keep
    security-sensitive packages visible in module READMEs.
  - Completed: `docs/package-inventory.md` now records the package inventory
    evaluation commands, package entry points, review questions, and failure
    modes. `modules/README.md` and `pkgs/README.md` point maintainers back to
    that rite before package-bearing modules or local derivations grow.

- [x] Keep `allowUnfree = false` as the repository default and require explicit
  predicates for exceptions.
  - Why: proprietary software is harder to audit and often has weaker repair
    paths.
  - How: preserve the current flake posture and ensure any future unfree package
    uses a narrow allow predicate instead of a global toggle.
  - Achieves: a default that rejects unauditable software while allowing a named
    exception when the operator knowingly accepts it.
  - Default posture: already safe in this repository.
  - Validation: `nix eval .#nixosConfigurations.solanine.config.nixpkgs.config.allowUnfree`
    or equivalent predicate inspection during implementation.
  - Completed: `modules/nixos/base/nix.nix` keeps
    `nixpkgs.config.allowUnfree = false` and admits exceptions only through
    `allowUnfreePredicate` over
    `theorem.nixos.base.nix.unfreePackageNames`. The current host list is
    explicit in `hosts/solanine/profiles.nix`, with Steam-owned additions in
    `modules/nixos/gaming/steam.nix`. Validated on 2026-06-03 by evaluating the
    global switch, the exception list, and a predicate sample that allows
    `discord` while rejecting `hello`.

- [x] Keep stable plus unstable package strategy explicit.
  - Why: stable channels reduce surprise, while unstable often carries faster
    fixes for browsers, kernels, and other security-sensitive applications.
  - How: document where this repository uses `nixpkgs` and `nixpkgs-stable`;
    prefer stable OS foundations with selected unstable packages only where the
    security update cadence matters.
  - Achieves: clearer tradeoff between patch velocity and rebuild breakage.
  - Default posture: conditional. Do not migrate the whole system solely for
    hardening until package risk and rebuild risk are compared.
  - Validation: check flake inputs, then evaluate selected package origins.
  - Completed: this repository currently uses `nixpkgs` from `nixos-unstable`
    as the primary system package set. The `nixpkgs-stable` input is imported
    with `allowUnfree = false` and passed as `stable` through system and Home
    Manager special arguments, but no current module selects packages from it.
    The base boot module now sets `boot.kernelPackages` with `mkDefault` to
    `pkgs.linuxPackages_latest`, keeping the security-sensitive kernel on the
    freshest pinned unstable kernel while preserving a one-line host override
    for hardware or driver fallout.

## Install, Disk, And Persistence Posture

- [ ] Keep new installations minimal.
  - Why: a smaller base system starts with fewer services, fewer packages, and
    fewer mistakes to inherit.
  - How: make the bootstrap/install path use the minimal NixOS image and this
    flake's profiles rather than a large manual desktop image.
  - Achieves: clean first boot and an easier audit trail.
  - Default posture: safe default for new hosts.
  - Validation: test bootstrap in a VM or disposable disk image before using real
    hardware.

- [ ] Require LUKS encryption for new physical hosts unless a host documents why
  data-at-rest encryption is impossible or inappropriate.
  - Why: encryption protects stored data from theft, loss, and unauthorized
    offline access.
  - How: use the repository installation path with LUKS and documented key
    handling; include remote unlock only where the host profile requires it.
  - Achieves: protected data at rest without inventing per-host disk rites.
  - Default posture: safe for laptops and most physical servers; conditional for
    constrained appliances or disposable VMs.
  - Validation: boot test media, verify encrypted devices, verify unlock path,
    and confirm rollback or rescue access.

- [ ] Prefer `disko` for encrypted Btrfs installs.
  - Why: declarative partitioning reduces manual installer drift.
  - How: extend the bootstrap TODO with a disko profile that creates encrypted
    Btrfs subvolumes and names destructive target disks explicitly.
  - Achieves: repeatable encrypted installs with a visible disk theorem.
  - Default posture: safe only in installer context; never run destructive disk
    actions without a named target device and host.
  - Validation: run the disko path against a disposable VM disk.

- [ ] Continue impermanence work as a hardening layer, not a casual default.
  - Why: ephemeral root defeats many persistence mechanisms after reboot.
  - How: finish the existing Btrfs rollback and persistence TODOs before any host
    selects destructive impermanence modes.
  - Achieves: fresh-root boot behavior with declared persistent state.
  - Default posture: conditional. Safe only after the storage layout and
    persistence inventory are tested.
  - Validation: VM reboot tests proving required state persists and unwanted
    state is wiped.

## Desktop, Display, And Portal Posture

- [ ] Prefer desktops/compositors with protected privileged Wayland protocols.
  - Why: some Wayland environments expose screen capture protocols that can leak
    other application contents.
  - How: document GNOME, KDE Plasma, and Sway as safer defaults for screencopy
    mediation; treat less-protected compositors as requiring explicit review.
  - Achieves: lower risk of accidental full-desktop capture.
  - Default posture: safe documentation default; implementation depends on the
    desktop profile.
  - Validation: confirm portal backend and screen-sharing behavior per desktop.

- [ ] Decide whether the disposable browser should use LibreWolf, Mullvad
  Browser, or both.
  - Why: fingerprint resistance is hard to bolt onto a normal browser. Mullvad
    Browser is designed around the Tor Browser privacy model without the Tor
    network, while LibreWolf is already packaged and wrapped in this repository
    as the current disposable browser.
  - How: compare `pkgs.librewolf` and `pkgs.mullvad-browser` under the same
    Firejail constraints; check package maintenance, launch behavior,
    persistence expectations, profile management, and breakage under existing
    hardening.
  - Achieves: a named browser role instead of a half-private browser with
    folklore preferences.
  - Default posture: conditional. Keep the current LibreWolf wrapper until the
    Mullvad path is tested and rollback is trivial.
  - Validation: launch the wrapper, inspect profile directories after exit,
    verify no persistent browser state is written outside intended paths, and
    confirm package availability in the pinned nixpkgs input.

- [ ] Fold browser policy hardening into reusable browser modules.
  - Why: telemetry, studies, sponsored suggestions, Pocket, weak TLS policy, and
    unsafe plugin handling are browser attack surface and privacy surface, but
    browser preferences drift quickly.
  - How: move stable Firefox-family policy into module settings or enterprise
    policies after checking the currently supported preference and policy names.
    Keep settings that break normal browsing behind explicit options.
  - Achieves: browser hardening that can be evaluated and reviewed rather than
    pasted into comments.
  - Default posture: safe for telemetry and update-policy controls; conditional
    for fingerprinting, plugin MIME restrictions, session behavior, and form
    fill because these can break expected workflows.
  - Validation: evaluate the Firefox and Jailwolf modules, launch each browser,
    inspect `about:policies` or generated profile preferences, and test login,
    downloads, PDF handling, and at least one WebAuthn flow.

- [ ] Add secure browser search defaults without deleting fallback engines.
  - Why: default search engines leak routine intent. Removing every mainstream
    fallback can also make repair harder when privacy engines fail.
  - How: set a privacy-preserving default such as Startpage or a chosen SearXNG
    instance, add NixOS/Home Manager/package search shortcuts, and keep
    mainstream engines available but non-default unless a stricter profile opts
    out.
  - Achieves: better defaults for daily use without turning search configuration
    into a fragile purity test.
  - Default posture: safe when configured per browser profile; instance choice
    must remain explicit if a SearXNG endpoint is operator-owned.
  - Validation: verify the generated browser profile contains the expected
    default engine, run searches through the configured shortcuts, and confirm
    fallback engines are present but not selected.

- [ ] Add a Sway-only hardening task for disabling Xwayland where practical.
  - Why: disabling Xwayland removes an older compatibility surface when the user
    does not need X11 applications.
  - How: set `wayland.windowManager.sway.extraConfig = "xwayland disable"` in a
    Sway Home Manager profile only when no X11 applications are required.
  - Achieves: smaller display-server attack surface.
  - Default posture: conditional. Do not apply to Plasma or to profiles that need
    X11 compatibility.
  - Validation: reboot into Sway and launch the expected application set.

- [ ] Disable `xdg-desktop-portal-wlr` where it is installed but not required.
  - Why: the guide calls out the WLR portal screencopy surface as a privacy risk
    outside stronger desktop mediation.
  - How: set `systemd.user.services."xdg-desktop-portal-wlr".enable = false`
    and `xdg.portal.wlr.enable = false` only for affected WLR setups.
  - Achieves: reduced screen capture exposure.
  - Default posture: conditional; avoid breaking legitimate screen sharing until
    the compositor and portal stack are known.
  - Validation: inspect user units and test portal-dependent workflows.

## Privilege, Users, SUID, And Capabilities

- [ ] Finish the `run0` profile before making it the default elevation path.
  - Why: replacing `sudo` removes a common SUID elevation binary, but privilege
    rules can lock out administration if the user model is wrong.
  - How: continue `modules/nixos/security/run0.nix`; require declared admin
    users or groups; keep `security.polkit.enable = true`; keep the sudo alias
    as a compatibility option until host repair notes no longer depend on it.
  - Achieves: privilege escalation through systemd-run/Polkit rather than the
    traditional `sudo` SUID binary.
  - Default posture: conditional until every host has a tested admin account and
    recovery path.
  - Validation: run `run0 true`, `run0 nixos-rebuild dry-build --flake .#host`,
    and confirm rollback access.
  - Progress: `modules/nixos/security/run0.nix` now rejects simultaneous
    selection with the sudo theorem, requires at least one declared Polkit cache
    user or group, and exposes
    `theorem.nixos.security.run0-sudo.sudoAlias.enable` instead of hard-coding
    the compatibility alias.

- [ ] Separate daily users from administrator accounts where the host can bear
  it.
  - Why: least privilege limits the blast radius of browser, editor, or chat
    compromise.
  - How: keep `admin` as a declared administrative user; remove daily users from
    `wheel` on profiles that can tolerate separate authentication; preserve
    necessary non-admin groups explicitly.
  - Achieves: reduced routine privilege exposure.
  - Default posture: conditional. Good server default; desktop convenience needs
    analysis.
  - Validation: login as daily user, confirm no `wheel`; authenticate as admin;
    test common desktop operations.

- [ ] Keep `users.mutableUsers = false` wherever declarative user management is
  complete.
  - Why: imperative password or user drift weakens reproducibility and hides
    access changes outside the flake.
  - How: ensure every declared account has a managed password hash or secret
    path before forcing immutability.
  - Achieves: account state that can be reviewed and rebuilt.
  - Default posture: safe only after secrets and recovery accounts are in place.
  - Validation: rebuild, reboot, and login with every intended account.

- [ ] Audit and minimize active SUID wrappers.
  - Why: SUID binaries are local privilege escalation pathways when they contain
    flaws.
  - How: compare `/run/wrappers/bin` with `security.wrappers`; disable unused
    wrappers such as `su`, `sudoedit`, `sg`, `pkexec`, `newgrp`,
    `newuidmap`, `newgidmap`, `fusermount`, and `fusermount3` where host
    features do not require them.
  - Achieves: smaller local root attack surface.
  - Default posture: mostly safe with derived exceptions. Keep FUSE wrappers
    when AppImage or user FUSE is enabled; keep uid/gid map wrappers when
    unprivileged containers or namespaces are required.
  - Validation: `find /run/wrappers -perm -4000 -ls` before and after; test
    AppImage, Podman, Flatpak, and mount workflows as applicable.

- [ ] Validate Bluetooth service hardening on real hardware before tightening
  it further.
  - Why: BlueZ is a hardware-facing daemon. Aggressive sandboxing can build
    cleanly while causing pairing, firmware, suspend/resume, or headset
    reconnect failures during normal use.
  - How: keep `modules/nixos/desktop/bluetooth.nix` limited to low-risk service
    guards unless logs prove a stronger restriction is safe for the adapter
    fleet.
  - Achieves: fewer ambient daemon permissions without making the audio and
    input repair path brittle.
  - Default posture: conservative. Do not add `ProtectKernelModules`,
    `ProtectProc`, or broad `SystemCallFilter` rules to `bluetooth.service`
    until the host has passed runtime tests.
  - Validation: pair a device, reconnect a headset, switch audio profiles,
    suspend and resume, then inspect `journalctl -u bluetooth -b`,
    `journalctl -k -b` for `bluetooth|btusb|firmware|hci|usb`, and the boot log
    for denial, seccomp, or syscall errors.

- [x] Do not disable `unix_chkpwd`.
  - Why: it is a core PAM helper for checking passwords against shadow data.
  - How: add it to the hardening compatibility matrix as forbidden to disable.
  - Achieves: avoids breaking local authentication in pursuit of a false
    reduction.
  - Default posture: never disable.
  - Validation: confirm it remains available after wrapper hardening.
  - Completed: `docs/hardening-compatibility.md` names this as a forbidden
    shortcut. Future SUID wrapper minimization must preserve the PAM helper and
    verify authentication after any wrapper change.

- [ ] Treat Linux capabilities as a research path, not an immediate default.
  - Why: capabilities can replace broad SUID root with narrower privileges, but
    incorrect assignments still grant powerful authority.
  - How: inventory wrappers that might be replaced with capabilities, starting
    with network tools such as `ping` or `mtr-packet`; document capability
    purpose before assigning it.
  - Achieves: possible least-privilege replacements for selected SUID uses.
  - Default posture: research only until each candidate is proven.
  - Validation: inspect `/proc/<pid>/status`, use `capsh --print`, and test the
    exact command behavior.

## Time, Boot, Kernel, And Sysctl

- [x] Replace or supplement `timesyncd` with Chrony using Network Time Security.
  - Why: NTS authenticates time synchronization and reduces tampering risk.
  - How: enable `services.chrony.enable = true` and
    `services.chrony.enableNTS = true`; choose a small, maintained server set;
    decide whether `timesyncd` must be disabled explicitly.
  - Achieves: authenticated network time for hosts that depend on correct clocks.
  - Default posture: likely safe, but verify service interactions first.
  - Validation: `chronyc -N authdata` shows NTS authentication.
  - Completed: the hardening profile now enables Chrony with NTS by default,
    selects `time.cloudflare.com`, `sth1.nts.netnod.se`, and
    `sth2.nts.netnod.se` as the initial maintained server set, and uses
    `mkForce false` for `services.timesyncd.enable` while Chrony NTS owns the
    clock. Hosts can disable `theorem.nixos.security.hardening.timeSync.chronyNts`
    or override its `servers` list when locality, firewall policy, or provider
    trust requires another time source.

- [ ] Add Secure Boot/lanzaboote as a separate project.
  - Why: Secure Boot helps ensure only trusted kernels and bootloaders execute
    during startup.
  - How: create a dedicated plan for UEFI admin password posture, lanzaboote,
    key enrollment, rollback, and recovery media.
  - Achieves: stronger boot-chain integrity.
  - Default posture: conditional. Do not fold into baseline until enrollment and
    recovery are tested per machine.
  - Validation: boot signed generations and test recovery from a failed signing
    or bootloader update.

- [ ] Decide whether to import NixOS `profiles/hardened.nix`.
  - Why: the hardened profile bundles many security settings, but the guide
    notes possible removal discussions and the need to inspect exact contents.
  - How: diff the profile against this repository's explicit hardening module;
    avoid duplicates and hidden conflicts.
  - Achieves: either a justified import or a deliberate local replacement.
  - Default posture: research only.
  - Validation: evaluate merged options and compare `sysctl`/kernel parameters
    before and after in a test generation.

- [ ] Keep the default kernel unless a host profile proves it can tolerate the
  hardened kernel.
  - Why: `linuxPackages_hardened` prioritizes security but breaks common
    workflows that require unprivileged user namespaces, including Flatpak and
    Chromium-family browser sandboxes, and can affect kernel-specific drivers.
  - How: derive hardened-kernel eligibility from disabled Flatpak, no Chromium
    dependency, no affected browser stack, and compatible NVIDIA/VirtualBox or
    other out-of-tree modules.
  - Achieves: stronger kernel hardening where the host does not need conflicting
    features.
  - Default posture: conditional. Headless server candidates first; desktop
    default remains normal kernel until proven.
  - Validation: build and boot a specialization with `boot.kernelPackages =
    pkgs.linuxPackages_hardened`, then test declared workloads.

- [x] Add kernel hardening checker tooling to a diagnostics profile.
  - Why: `kernel-hardening-checker` gives a repeatable way to compare kernel
    config, command line, and sysctl posture.
  - How: expose `pkgs.kernel-hardening-checker` through an optional diagnostics
    profile, not as global runtime cruft.
  - Achieves: measurable hardening audits.
  - Default posture: optional tool, safe when needed.
  - Validation: run `kernel-hardening-checker -l /proc/cmdline -c
    /proc/config.gz -s ./params.txt` after capturing `sysctl -a`.
  - Progress: `theorem.nixos.security.diagnostics` now exists as an opt-in tool
    profile. `kernel-hardening-checker` still needs exact package verification
    against the pinned nixpkgs before it is referenced.
  - Completed: `modules/nixos/security/diagnostics.nix` now exposes
    `theorem.nixos.security.diagnostics.kernelAudit.enable`, defaulting on when
    the diagnostics profile is enabled. The pinned package set contains
    `pkgs.kernel-hardening-checker`, and Solanine's diagnostics profile installs
    it as a manual audit tool.

- [x] Apply low-risk `security.*` kernel protections.
  - Why: kernel image protection, page table isolation, and namespace policy
    reduce kernel attack paths.
  - How: start with `security.protectKernelImage = true` and
    `security.forcePageTableIsolation = true`; keep
    `security.lockKernelModules = false` until WireGuard, iptables, and
    virtualization breakage is resolved; derive
    `security.unprivilegedUsernsClone` from container/browser/Flatpak needs.
  - Achieves: safer kernel defaults without sacrificing known required
    workloads.
  - Default posture: partial safe default with derived exceptions.
  - Validation: targeted `nix eval` of derived values and host dry-build.
  - Completed: the hardening profile sets `security.protectKernelImage` and
    `security.forcePageTableIsolation` with `mkDefault`, leaves
    `security.lockKernelModules` off, and derives
    `security.unprivilegedUsernsClone` from Flatpak or Podman enablement.

- [ ] Add conservative sysctl defaults in tiers.
  - Why: sysctl settings reduce kernel information leaks, restrict debugging
    interfaces, harden networking, and defend user-space filesystem link traps.
  - How: split `boot.kernel.sysctl` into safe, conditional, and aggressive
    groups. Start with values such as coredump restrictions, pointer/log
    restrictions, protected links/FIFOs/regular files, ASLR, ptrace restrictions,
    kexec disablement, dmesg restriction, and common redirect/source-route
    network hardening.
  - Achieves: runtime kernel hardening with override points.
  - Default posture: safe group should be default; conditional group must account
    for containers, browser sandboxes, routing, VPN, IPv6 router advertisements,
    and debugging.
  - Validation: compare `sysctl -a` before/after, run network tests, container
    tests, browser tests, and VPN tests.

- [ ] Reject or quarantine questionable sysctl items before implementation.
  - Why: the guide includes aggressive and environment-sensitive values, and at
    least one historical/unsupported-looking key (`kernel.exec-shield`) may not
    be valid on current NixOS kernels.
  - How: verify every sysctl exists on the target kernel before adding it; do
    not apply `net.ipv4.icmp_echo_ignore_all = 1` to hosts expected to answer
    ping; do not disable IPv6 RA or forwarding on routers; do not force
    `kernel.unprivileged_userns_clone = 0` where Flatpak, Docker, NH, or browser
    sandboxes need it.
  - Achieves: no cargo-cult sysctl failures.
  - Default posture: research and host-derived only.
  - Validation: `sysctl -a | rg '<key>'` on the target generation.

- [ ] Add kernel boot parameters only after hardware and workload testing.
  - Why: boot parameters can improve memory safety and kernel lockdown, but some
    break debugging, unsigned modules, NVIDIA, VirtualBox, or other kernel
    module workflows.
  - How: evaluate `slab_nomerge`, `init_on_alloc=1`, `init_on_free=1`,
    page allocator randomization, `pti=on`, `randomize_kstack_offset=on`,
    `vsyscall=none`, `debugfs=off`, `oops=panic`, `module.sig_enforce=1`, and
    `lockdown=confidentiality` as separate switches or tiers.
  - Achieves: stronger kernel memory and lockdown posture where supported.
  - Default posture: safe subset only after spelling and kernel support checks;
    module signature enforcement and lockdown remain conditional.
  - Validation: inspect `/proc/cmdline`, boot twice, and test hardware drivers.

- [ ] Harden module loading and blacklist unused kernel modules.
  - Why: unused protocols, filesystems, FireWire, and Thunderbolt paths increase
    kernel attack surface.
  - How: use `boot.extraModprobeConfig` for forced install failures and
    `boot.blacklistedKernelModules` for unused protocols/filesystems such as
    DCCP, SCTP, RDS, TIPC, rare network protocols, and rare filesystems.
  - Achieves: less auto-loadable kernel surface.
  - Default posture: conditional. Do not block Thunderbolt, FireWire, CIFS, NFS,
    UDF, HFS/HFS+, or CAN on hosts that need them.
  - Validation: boot and verify required devices, filesystems, networking, and
    removable media still work.

- [ ] Evaluate `environment.memoryAllocator.provider =
  "graphene-hardened-light"` as a conditional desktop/server default.
  - Why: hardened allocators reduce exploitability of memory corruption bugs.
  - How: test the light Graphene allocator first; gate full
    `"graphene-hardened"` behind explicit opt-in. Derive default disablement if
    Firefox, Thunderbird, Tor Browser, LibreWolf, Zen Browser, or another known
    incompatible program is present unless a working workaround is documented.
  - Achieves: stronger heap behavior where applications tolerate it.
  - Default posture: conditional; never blind global default.
  - Validation: launch browsers, Electron apps, media tools, and long-running
    services under the selected allocator.

## systemd, Logs, And Service Reduction

- [x] Disable coredumps globally by default.
  - Why: coredumps can contain passwords, encryption keys, messages, form data,
    and other private memory from crashed processes.
  - How: set `systemd.coredump.enable = false` and
    `security.pam.loginLimits` core size to `0`.
  - Achieves: reduced sensitive memory leakage and less crash dump storage.
  - Default posture: safe default. Provide an opt-out debugging specialization
    or option.
  - Validation: `ulimit -c` in a login shell and systemd coredump status.
  - Completed: the hardening profile disables `systemd.coredump` by default for
    opted-in hosts and adds a PAM core-size limit of `0`. A future debugging
    specialization can override the profile option.

- [ ] Switch D-Bus to `dbus-broker` if desktop and service tests pass.
  - Why: dbus-broker is designed to be more robust against resource exhaustion
    and integrates well with Linux security features.
  - How: set `services.dbus.implementation = "broker"` behind the hardening
    profile.
  - Achieves: stronger message-bus behavior.
  - Default posture: likely safe, but test Plasma, portals, Flatpak, and user
    services first.
  - Validation: boot graphical session, test portals, and inspect dbus service
    health.
  - Progress: the hardening profile now exposes
    `theorem.nixos.security.hardening.dbusBroker.enable`, but leaves it disabled
    until the desktop and portal path is tested.

- [ ] Calibrate journald and log retention.
  - Why: logs can leak sensitive data and fill disks, but volatile-only logs
    weaken post-reboot debugging and auditing.
  - How: set `services.journald.upload.enable = false`; set size limits through
    `services.journald.extraConfig`; decide per host whether
    `services.journald.storage = "volatile"` is acceptable.
  - Achieves: bounded logs and no accidental remote upload.
  - Default posture: upload disabled and size limits safe; volatile storage
    conditional.
  - Validation: `journalctl --disk-usage`, reboot log availability check, and
    incident-response needs review.
  - Progress: the hardening profile disables journal upload by default and sets
    bounded local journal storage. Volatile-only storage remains host-specific
    because it changes post-reboot diagnosis.

- [x] Enable logrotate where legacy logs exist.
  - Why: classic text logs can grow until they consume disk.
  - How: set `services.logrotate.enable = true` where packages produce files
    outside journald.
  - Achieves: bounded legacy log growth.
  - Default posture: safe default.
  - Validation: dry-build and inspect generated logrotate units.
  - Completed: opted-in hardening hosts enable `services.logrotate` by default,
    while file-specific rotation rules remain with the services that produce
    legacy text logs.

- [ ] Disable unused services by derived default.
  - Why: services such as Avahi, Geoclue, UDisks2, accounts-daemon,
    ModemManager, Bluetooth, and auto-upgrade expand network, hardware, privacy,
    or surprise-change surface.
  - How: set defaults from host capabilities: disable Avahi unless service
    discovery is requested; disable Geoclue unless location services are needed;
    disable ModemManager unless WWAN is present; disable Bluetooth unless a
    Bluetooth profile is enabled; disable auto-upgrade unless the host chooses
    unattended maintenance; treat UDisks2 and accounts-daemon carefully on
    desktops.
  - Achieves: fewer idle daemons.
  - Default posture: mostly safe for servers; conditional for desktops.
  - Validation: `systemctl status` for removed services and desktop workflow
    tests for removable media, user switching, discovery, and Bluetooth.

- [ ] Add a service-hardening review loop using `systemd-analyze security`.
  - Why: service sandboxing raises the baseline for long-running daemons.
  - How: use `systemd.services.<name>.serviceConfig` for selected services,
    starting with existing services in this repository: Bluetooth,
    NetworkManager, wpa_supplicant, dbus, nscd, systemd-rfkill,
    systemd-machined, systemd-udevd, nix-daemon, journald, auditd, CUPS, and
    acpid only when those services are enabled.
  - Achieves: lower service exposure without applying irrelevant hardening to
    absent units.
  - Default posture: conditional and service-specific. Avoid broad copied
    settings until each unit boots cleanly.
  - Validation: `systemd-analyze security <unit>`, unit startup logs, and
    workload tests.

## Auditing, Malware Scanning, And Vulnerability Scans

- [x] Add a diagnostics/audit profile with Lynis, AIDE, ClamAV, `sbomnix`, and
  `grype` as explicit tools.
  - Why: audit tools make hardening measurable and reveal drift, but they are
    not all necessary runtime dependencies.
  - How: expose tools through a maintenance profile or flake app instead of
    default installation everywhere.
  - Achieves: repeatable audits without bloating every host.
  - Default posture: optional tool profile.
  - Validation: run `lynis audit system` and the SBOM vulnerability scan on a
    test host.
  - Completed: `modules/nixos/security/diagnostics.nix` exposes an opt-in
    diagnostics profile. Lynis and SBOM/vulnerability tools default on when the
    profile is enabled; AIDE and ClamAV remain explicit sub-options because
    their databases, definitions, and scan cadence need separate stewardship.

- [ ] Design an AIDE module before enabling file integrity checks.
  - Why: AIDE can detect unexpected system-file changes, but its database must
    be initialized, persisted, and intentionally updated after system changes.
  - How: create declarative config, persistent database/log paths, init/update
    commands, and operator notes for rebuild/update cycles.
  - Achieves: intrusion-detection signal for hosts that can maintain the
    database.
  - Default posture: conditional. Good candidate for servers; noisy on rapidly
    changing desktops unless scoped.
  - Validation: initialize database, run `aide --check`, make a controlled file
    change, confirm detection, then update database.
  - Progress: the diagnostics profile can install the AIDE CLI for manual
    experiments, but it still does not initialize, persist, schedule, or update
    an AIDE database.

- [ ] Decide between ClamAV daemon scanning and cron-based `clamscan`.
  - Why: malware scanning can be useful, but daemon scanning and one-shot scans
    have different permissions and resource behavior.
  - How: use either `services.clamav.daemon/updater/scanner` or a scheduled
    `clamscan`, not both by accident; define scan paths and logs explicitly.
  - Achieves: intentional malware scan coverage.
  - Default posture: conditional. Avoid enabling expensive scans globally until
    paths and resource limits are known.
  - Validation: test scan permissions, update frequency, log path, and resource
    usage.
  - Progress: the diagnostics profile can install ClamAV command-line tooling
    for manual scans, but no daemon, updater, scanner, or scheduled job is
    enabled.

## SSH And Secrets

- [x] Harden the existing OpenSSH module.
  - Why: SSH is a remote entry point; password login, root login, forwarding, and
    weak limits increase exposure.
  - How: extend `modules/nixos/base/ssh.nix` beyond the current baseline with
    `PermitEmptyPasswords = false`, `PermitTunnel = false`, `MaxAuthTries = 3`,
    `MaxSessions = 2`, `ClientAliveInterval = 300`,
    `ClientAliveCountMax = 0`, `TCPKeepAlive = false`,
    `AllowTcpForwarding = false`, `AllowAgentForwarding = false`,
    `LogLevel = "VERBOSE"`, and explicit `hostKeys` where appropriate.
  - Achieves: key-only remote access with less forwarding and better audit logs.
  - Default posture: safe for managed hosts, but `AllowUsers` and forwarding
    must be host-specific to avoid lockout or breaking Git/automation tunnels.
  - Validation: remote login test from a second session before closing the first,
    then `nixos-rebuild dry-build`.
  - Completed: `modules/nixos/base/ssh.nix` now applies conservative server
    defaults with `mkDefault`, including lower auth/session limits, disabled
    tunnel and forwarding surfaces, and verbose authentication logging. Host
    allow-lists, forwarding exceptions, and explicit host keys remain separate.

- [ ] Add Fail2Ban where SSH is exposed beyond trusted networks.
  - Why: Fail2Ban reduces brute-force pressure by banning repeated failed
    attempts.
  - How: set `services.fail2ban.enable = true`; tune retry, ban time, increment,
    maximum ban, and ignore lists per host.
  - Achieves: automated response to repeated authentication failures.
  - Default posture: conditional. Safe for internet-exposed SSH; may be
    unnecessary or annoying on trusted-only networks.
  - Validation: inspect jail status and confirm trusted addresses are not banned.

- [x] Standardize SSH key guidance on Ed25519.
  - Why: Ed25519 keys are modern, small, fast, and strong for normal SSH use.
  - How: document `ssh-keygen -t ed25519 -a 32` in user/host README guidance;
    choose either `ssh-agent` or `gpg-agent`, not both, per user profile.
  - Achieves: better key hygiene and fewer agent conflicts.
  - Default posture: documentation default.
  - Validation: generate a test key, verify agent loading, and test SSH auth.
  - Completed: `users/README.md` now documents the Ed25519 key-generation rite
    and the one-agent rule. The existing Home Manager SSH module restores
    `id_ed25519` from SOPS-backed secrets, and the system SSH module uses the
    OpenSSH agent by default.

- [x] Keep secrets encrypted with `sops-nix`; do not introduce plaintext secret
  paths.
  - Why: secrets in the repository must not enter the Nix store or Git history
    unencrypted.
  - How: continue the existing `sops` modules and document where new secrets
    belong.
  - Achieves: declarative secret use without plaintext repository exposure.
  - Default posture: already safe; keep enforcing it.
  - Validation: `rg` for likely secret literals, `sops` decrypt test on intended
    host, and dry-build.
  - Completed: `modules/nixos/security/sops.nix`, `hosts/solanine/secrets.nix`,
    and `secrets/README.md` keep secret material under SOPS and document the
    plaintext failure modes. The repository scan should keep ignoring encrypted
    `secrets/*.yaml` payloads while checking Nix and script files for obvious
    private keys, age identities, passwords, tokens, and API keys.

## USB And Physical-Port Protection

- [ ] Add USBGuard as an opt-in hardening module with a boot specialization that
  disables it.
  - Why: USBGuard can block BadUSB devices, data-exfiltration gadgets, and
    suspicious composite devices, but bad rules can lock out keyboards and mice.
  - How: create `theorem.nixos.security.usbguard` with
    `services.usbguard.enable`, `IPCAllowedUsers`, `presentDevicePolicy`, and
    explicit rules; also create `specialisation.no-usbguard.configuration` to
    force-disable it at boot.
  - Achieves: physical port control with a recovery path.
  - Default posture: conditional. Do not enable globally until each host's input
    devices and dock behavior are tested.
  - Validation: `usbguard list-devices`, plug known devices, plug a test-denied
    class if available, and boot the no-USBGuard specialization.

## Application Sandboxing

- [x] Treat Firejail as an explicit per-application profile, not a blanket
  default.
  - Why: Firejail can sandbox applications but is itself SUID and has critics
    who treat it as additional privilege-escalation surface.
  - How: keep `modules/nixos/security/firejail.nix`; add
    `programs.firejail.wrappedBinaries` only for selected binaries with known
    profiles and tested behavior.
  - Achieves: containment for selected applications without pretending Firejail
    is pure hardening.
  - Default posture: conditional; never wrap unknown workloads blindly.
  - Validation: launch each wrapped app normally, inspect confinement, and test
    file access expectations.
  - Completed: `modules/nixos/security/firejail.nix` only enables the substrate
    and optional CLI. `modules/nixos/desktop/jailwolf.nix` owns the single
    current wrapped binary, `librewolf-private`, with an explicit profile and
    desktop entry. Evaluated Solanine currently has Firejail enabled, Flatpak
    disabled, and only that named wrapped binary.

- [ ] Evaluate Bubblewrap/nix-bwrapper as a lower-SUID sandboxing research path.
  - Why: Bubblewrap has a smaller design and may avoid some Firejail concerns.
  - How: compare nix-bwrapper or nix-bubblewrap with existing Firejail and
    Flatpak modules for target applications.
  - Achieves: possible app confinement with less privilege surface.
  - Default posture: research only.
  - Validation: prototype one GUI app and one file-opening workflow.

- [ ] Harden Flatpak support around permissions and portals.
  - Why: Flatpak gives useful GUI sandboxing on NixOS, but permissive app
    defaults can weaken the sandbox.
  - How: continue `modules/nixos/desktop/flatpak.nix`; add Flathub remotes
    deliberately; prefer verified apps where practical; manage permissions with
    declarative overrides, Flatseal, or Warehouse guidance.
  - Achieves: isolated GUI apps with reviewed host access.
  - Default posture: conditional desktop feature. It conflicts with the hardened
    kernel because Flatpak needs unprivileged user namespaces.
  - Validation: install a test app, inspect permissions, verify portals, and
    launch under the selected desktop.

- [x] Do not combine Firejail with Flatpak applications.
  - Why: the guide notes that the sandboxing technologies do not layer cleanly.
  - How: encode mutual exclusion in documentation or module assertions if both
    systems try to own the same app.
  - Achieves: fewer false assurances and less launch breakage.
  - Default posture: safe rule.
  - Validation: evaluate app ownership lists.
  - Completed: `docs/hardening-compatibility.md` names this as a forbidden
    shortcut. If future modules grow explicit Flatpak app lists and Firejail
    wrapped binaries for the same application, add module assertions then.

- [x] Treat Flatpak browsers as a specific research item.
  - Why: browser sandboxes and Flatpak sandboxing may trade off in non-obvious
    ways; the guide notes concern that Flatpak can reduce built-in browser
    sandboxing.
  - How: compare native Firefox/Chromium hardening with Flatpak variants before
    moving browsers into Flatpak.
  - Achieves: browser isolation chosen by evidence, not fashion.
  - Default posture: research only.
  - Validation: inspect sandbox status and browser security diagnostics.
  - Completed: `docs/hardening-compatibility.md` records Flatpak browsers as a
    research-only mechanism and forbids moving browsers into Flatpak without
    comparing native and Flatpak sandbox diagnostics.

## MAC Frameworks And External Baselines

- [ ] Track AppArmor support but do not make it a conservative default yet.
  - Why: AppArmor exists on NixOS, but profile coverage is still limited and
    evolving.
  - How: document available NixOS-adapted profiles and evaluate one low-risk
    service profile in a test host.
  - Achieves: future path toward MAC without destabilizing all hosts.
  - Default posture: research only.
  - Validation: profile load status, service behavior, and denials in logs.

- [x] Treat SELinux as out of baseline scope.
  - Why: SELinux remains experimental and not fully integrated for normal NixOS
    systems.
  - How: keep references for advanced research, but do not add module defaults.
  - Achieves: avoids spending the conservative baseline on rough edges.
  - Default posture: no default.
  - Validation: none until a separate SELinux project is opened.
  - Completed: `docs/hardening-compatibility.md` keeps SELinux out of the
    conservative baseline and requires a separate project before any policy,
    labeling, or recovery work is attempted.

- [ ] Review `nix-mineral` as an external reference, not an import target.
  - Why: it is a broad community hardening module and the guide describes it as
    alpha-status community software.
  - How: mine it for individual settings and compare them to this ledger; do not
    import wholesale without a dedicated compatibility project.
  - Achieves: useful prior art without surrendering local understanding.
  - Default posture: research only.
  - Validation: diff settings, evaluate test host, and record breakages.

- [x] Add vulnerability/SBOM scan command as a maintenance rite.
  - Why: SBOM plus vulnerability scanning can reveal known vulnerable packages in
    the current system closure.
  - How: package a flake app or documented command using `sbomnix` and `grype`
    against `/run/current-system`.
  - Achieves: repeatable vulnerability checks for deployed hosts.
  - Default posture: optional maintenance command.
  - Validation: run scan, archive or summarize findings, and decide patching
    actions.
  - Progress: the diagnostics profile can install `sbomnix` and `grype` when
    selected. A wrapper command or flake app that chooses the target closure and
    output format remains open.
  - Completed: `flake.nix` exposes `.#vulnerability-scan`, a flake app that
    defaults to `/run/current-system`, writes a CycloneDX SBOM with `sbomnix`,
    and scans that SBOM with `grype`. Use `nix run .#vulnerability-scan -- --help`
    to inspect the rite without running a scan.

## Implementation Order

1. Safe defaults still open: package hygiene review and service-disable defaults
   derived from existing module enables.
2. Derived defaults: SUID wrapper minimization, sysctl safe tier,
   Flatpak/portal posture, Fail2Ban, and selected service hardening.
3. Host-sensitive mechanisms: USBGuard, impermanence, hardened allocator,
   hardened kernel, boot parameters, module blacklists, Secure Boot, AIDE, and
   ClamAV.
4. Research-only mechanisms: capabilities replacement, Bubblewrap alternatives,
   AppArmor, SELinux, nix-mineral import strategy, and Flatpak browser posture.

## Validation Rites

- Run `nix flake check` after each module batch.
- Use targeted `nix eval` for derived hardening defaults and assertions.
- Use `nixos-rebuild dry-build --flake .#<host>` before any activation.
- Prefer `nixos-rebuild test` before `switch` on local NixOS hosts.
- For remote hosts, keep a second SSH session open and verify rollback access.
- For risky hardening, create a specialization that disables the mechanism
  before enabling the mechanism itself.
