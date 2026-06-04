# NixOS Hardening Compatibility Matrix

This matrix records the known pressure points for the conservative hardening
profile. It is not a permission slip to avoid hardening. It is the calibration
bench: before a sharp option becomes a default, name the workload it can break
and the host signal that proves it is safe.

## Host Signals

| Signal | Current Repository Source | Why It Matters |
|---|---|---|
| Graphical desktop | `theorem.nixos.desktop.plasma.enable` | Desktops need portals, Polkit, removable-media handling, and screen-sharing tests before service reduction. |
| Flatpak support | `theorem.nixos.desktop.flatpak.enable` | Flatpak requires unprivileged user namespaces and portal behavior; it conflicts with some hardened-kernel assumptions. |
| Chromium-family browser | `theorem.home.web.ungoogled-chromium.enable` | Chromium sandboxes usually rely on unprivileged user namespaces. Hardened-kernel and namespace policy must respect that. |
| Firefox-family browser | `theorem.home.web.firefox.enable` | Browser sandbox and allocator behavior need runtime checks before hardened allocators become defaults. |
| Rootless containers | `theorem.nixos.virtualisation.podman.enable` | Rootless Podman needs namespace support and related SUID helpers such as `newuidmap` and `newgidmap`. |
| Docker-compatible Podman | `theorem.nixos.virtualisation.podman.dockerCompat.enable` and `dockerSocket.enable` | Compatibility shims and sockets widen local control of the container engine. Treat them as workflow-specific choices. |
| AppImage support | `theorem.nixos.desktop.appimage.enable` | AppImage and user FUSE can require FUSE wrappers. Do not remove those wrappers blindly. |
| Firejail-backed applications | `theorem.nixos.security.firejail.enable` | Firejail is useful confinement, but it is also SUID. Wrap only named applications with tested profiles. |
| Bluetooth | `theorem.nixos.desktop.bluetooth.enable` | Service reduction and service sandboxing must preserve paired input devices and recovery access. |
| Impermanence | `theorem.nixos.base.persistence.enable` and root mode options | Audit databases, logs, malware definitions, and restore paths need persistence decisions before scheduled checks. |
| Administrative elevation | `theorem.nixos.security.sudo.enable` or `run0-sudo.enable` | SUID wrapper reduction must not remove the only tested administrative path. |
| Encrypted DNS resolver | Not yet implemented | DNS privacy controls can break captive portals, VPN bootstrap, MagicDNS, local discovery, and browser DoH assumptions. |
| Tailscale mesh networking | Not yet implemented | Trusting `tailscale0`, MagicDNS, exit nodes, and DNS acceptance each changes recovery and name-resolution behavior. |
| MAC randomization | `theorem.nixos.security.hardening.networkManagerMacRandomization.enable` | Randomized addresses can confuse home routers, allow-lists, device inventory, and per-network firewall expectations. |
| Secure Boot / Lanzaboote | Not yet implemented | Boot-chain signing can lock out recovery if firmware, keys, dbx, LUKS, and rollback are not tested together. |
| GPG agent as SSH agent | Not yet implemented | `gpg-agent` with SSH support conflicts with OpenSSH-agent ownership unless the profile deliberately switches models. |
| NixOS containers | Not yet implemented | `systemd-nspawn` containers separate services, but are not a full security boundary without careful privilege and mount design. |
| Jujutsu workflow | Not yet implemented | JJ changes working-copy, branch/bookmark, conflict, and undo habits while sharing Git storage. Trial before making it a default. |

## Mechanism Compatibility

| Mechanism | Conservative Default | Known Breakage | Gate Before Enabling |
|---|---:|---|---|
| `security.protectKernelImage` | Enabled in the hardening profile | Disables hibernation through upstream kernel protection. | Confirm the host does not rely on hibernation, or override the profile option. |
| `security.forcePageTableIsolation` | Enabled in the hardening profile | Possible performance cost on some workloads. | Dry-build, boot, and watch interactive and VM/container workloads after activation. |
| `security.lockKernelModules` | Disabled | Late-loaded VPN, firewall, filesystem, hardware, and virtualization modules can fail. | Inventory loaded modules after normal use; add required modules declaratively before enabling. |
| Unprivileged user namespaces | Derived from Flatpak or Podman | Disabling can break Flatpak, rootless containers, Chromium sandboxes, and some developer tooling. | Keep enabled when Flatpak, Podman, or Chromium-family browsers are present. |
| Hardened kernel | Disabled | Can break Flatpak, Chromium sandboxes, out-of-tree drivers, VirtualBox, and other namespace-sensitive workflows. | Start with a headless specialization or test host; do not make it a desktop default. |
| Hardened allocator | Disabled | Browser and Electron applications may fail or become unstable. | Test Firefox, Chromium/Electron apps, media tools, and long-running services before enabling. |
| Kernel boot parameters | Disabled unless upstream options set them | Lockdown, module signature enforcement, debugfs changes, and panic behavior can harm recovery and drivers. | Add one tier at a time with a bootable rollback generation. |
| Sysctl safe tier | Enabled in the hardening profile | Network routing, VPN, IPv6 router advertisements, debugging, and namespace policy can regress. | Keep questionable keys in `docs/hardening-sysctl-quarantine.md`; verify every active key exists on the target kernel and test network/container/browser workflows. |
| SUID wrapper minimization | Not yet implemented | `mount`, FUSE, AppImage, Podman, Polkit, and administrative tools can fail. | Compare `/run/wrappers/bin` before and after; keep wrappers required by declared host features. |
| Bluetooth service sandboxing | Low-risk service guards only | Broad restrictions such as `ProtectKernelModules`, `ProtectProc`, or `SystemCallFilter` can break adapter firmware, pairing, suspend/resume, or headset reconnect behavior. | After any Bluetooth hardening change, test pairing, audio profile switching, suspend/resume, and reconnect; inspect `journalctl -u bluetooth -b` and kernel logs for `btusb`, firmware, HCI, denial, or syscall errors. |
| `dbus-broker` | Available as opt-in | Desktop portals and user services need session testing. | Boot Plasma, test portals, Flatpak if enabled, and inspect user service health. |
| Volatile-only journald | Disabled | Post-reboot incident diagnosis becomes weaker. | Decide per host whether privacy or forensic continuity matters more. |
| Fail2Ban | Disabled | Trusted LAN mistakes can ban the operator if ignore lists are wrong. | Enable only for exposed SSH and declare trusted address ranges. |
| dnscrypt-proxy / DoH / DoT | Not yet implemented | Local resolver routing can fail closed, bypass browser DNS, or conflict with VPN/Tailscale DNS. | Test local DNS listener, browser DNS path, captive portal behavior, VPN bootstrap, MagicDNS, and a documented fallback resolver. |
| nftables DNS egress enforcement | Not yet implemented | Blocking outbound DNS except the resolver process can break troubleshooting, captive portals, and local labs. | Gate behind a profile; verify resolver UID, `dig`, browser behavior, VPN/Tailscale, and emergency disable path. |
| NetworkManager MAC randomization | Available as opt-in | Networks may treat the host as a new device; allow-lists and router reservations can stop matching. | Test on home, trusted, and untrusted networks; disable the theorem option or override `networking.networkmanager.{wifi,ethernet}.macAddress` per host when identity must remain stable. |
| Chrony NTS | Enabled by the hardening profile | NTS-KE uses TLS on port 4460, and provider or firewall problems can leave the host unsynchronized. | Verify selected servers with `chronyc -N authdata`; override `theorem.nixos.security.hardening.timeSync.chronyNts.servers` when locality or trust requires a different source. |
| USBGuard | Disabled | Bad rules can block keyboards, mice, docks, and recovery devices. | Create a no-USBGuard boot specialization before enabling. |
| AIDE checks | Tool-only optional profile | Database churn is noisy on desktops and useless without persistence/update rites. | Design database paths, update command, and persistence before scheduling checks. |
| ClamAV scans | Tool-only optional profile | Daemons and broad scans can consume resources and create noisy logs. | Choose daemon or scheduled `clamscan`, not both by accident. |
| Flatpak browsers | Research only | Flatpak confinement and built-in browser sandboxes can trade strength in non-obvious ways. | Compare native and Flatpak variants with browser sandbox diagnostics before moving browsers into Flatpak. |
| Browser fingerprint policy | Research only | Standardization, randomization, extensions, sync accounts, and search defaults pull against each other. | Name the browser goal, keep extension count low, test fingerprint posture without overfitting, and verify MIME/search/password-manager behavior. |
| Lanzaboote | Research only | Wrong firmware mode, unsigned generations, lost Secure Boot keys, or missing LUKS recovery can make the host hard to boot or easy to tamper with. | Check `bootctl status`, `sbctl verify`, `sbctl status`, recovery media, rollback generation, dbx state, and UEFI admin password posture. |
| GPG-agent SSH mode | Research only | Missing pinentry or conflicting `SSH_AUTH_SOCK` can break SSH and Git signing in opaque ways. | Test `ssh-add -L`, `gpgconf --list-dirs agent-ssh-socket`, pinentry prompt, Git signing, and rollback to OpenSSH-agent. |
| NixOS containers | Research only | Privileged container root, writable bind mounts, broad host networking, and unmanaged state weaken isolation. | Prefer ephemeral/read-only designs first; test `nixos-container status`, service health, bind permissions, and state deletion. |
| OCI container hardening | Research only | Pulling mutable images, broad capabilities, inline secrets, or host port exposure can defeat the purpose of containment. | Use local images where practical, `environmentFiles` for secrets, narrow ports, `--cap-drop=ALL`, `no-new-privileges`, and explicit persistence. |
| Jujutsu | Research only | Collocated `.jj` state, detached Git HEAD expectations, bookmark movement, missing submodule support, or large-repo performance may surprise Git habits. | Trial in a disposable clone; test Git fallback, signed commits, fetch/push, shared permissions, undo, and cleanup. |
| SELinux baseline | Out of scope | SELinux on NixOS is not mature enough for this conservative baseline. | Open a separate project before evaluating SELinux policy, labels, and recovery behavior. |

## Forbidden Shortcuts

- Do not disable `unix_chkpwd`. It is a PAM password-check helper, not loose
  scrap metal.
- Do not combine Firejail with Flatpak for the same application unless a
  specific profile has been tested. Layered sandbox names do not equal layered
  safety.
- Do not move browsers into Flatpak as a fashion default. Compare the native
  browser sandbox with the Flatpak variant first.
- Do not force `kernel.unprivileged_userns_clone = 0` on hosts with Flatpak,
  rootless containers, Chromium-family browsers, or tools that need user
  namespaces.
- Do not import a broad external hardening module without diffing its settings
  against this repository's explicit profile.
- Do not enforce DNS privacy by blocking DNS traffic until the host has a
  tested resolver fallback and the browser DNS path is known.
- Do not enable `gpg-agent` SSH support beside OpenSSH-agent. Pick one owner for
  `SSH_AUTH_SOCK` per user profile.
- Do not treat NixOS containers, Docker, Podman, Firejail, or Flatpak as magic
  isolation. Name privileges, mounts, ports, namespaces, and escape hatches.
- Do not install JJ as a default Git replacement until a disposable trial proves
  the operator can still repair, sign, push, and fall back to Git.
- Do not add SELinux defaults to the baseline. Treat SELinux as a separate
  research project with its own recovery plan.

## Review Rite

Before a hardening mechanism moves from this matrix into configuration:

1. Verify the NixOS option path against the pinned nixpkgs.
2. Name the host signal that allows or blocks the mechanism.
3. Add an override or specialization for recovery where the failure mode can
   lock out access, input devices, networking, or boot.
4. Run `nix flake check` and `nixos-rebuild dry-build --flake .#<host>`.
5. After activation, test the workload named in the `Known Breakage` column.
