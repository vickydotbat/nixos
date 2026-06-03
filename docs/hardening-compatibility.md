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
| Sysctl safe tier | Not yet implemented | Network routing, VPN, IPv6 router advertisements, debugging, and namespace policy can regress. | Verify every key exists on the target kernel and test network/container/browser workflows. |
| SUID wrapper minimization | Not yet implemented | `mount`, FUSE, AppImage, Podman, Polkit, and administrative tools can fail. | Compare `/run/wrappers/bin` before and after; keep wrappers required by declared host features. |
| Bluetooth service sandboxing | Low-risk service guards only | Broad restrictions such as `ProtectKernelModules`, `ProtectProc`, or `SystemCallFilter` can break adapter firmware, pairing, suspend/resume, or headset reconnect behavior. | After any Bluetooth hardening change, test pairing, audio profile switching, suspend/resume, and reconnect; inspect `journalctl -u bluetooth -b` and kernel logs for `btusb`, firmware, HCI, denial, or syscall errors. |
| `dbus-broker` | Available as opt-in | Desktop portals and user services need session testing. | Boot Plasma, test portals, Flatpak if enabled, and inspect user service health. |
| Volatile-only journald | Disabled | Post-reboot incident diagnosis becomes weaker. | Decide per host whether privacy or forensic continuity matters more. |
| Fail2Ban | Disabled | Trusted LAN mistakes can ban the operator if ignore lists are wrong. | Enable only for exposed SSH and declare trusted address ranges. |
| Chrony NTS | Enabled by the hardening profile | NTS-KE uses TLS on port 4460, and provider or firewall problems can leave the host unsynchronized. | Verify selected servers with `chronyc -N authdata`; override `theorem.nixos.security.hardening.timeSync.chronyNts.servers` when locality or trust requires a different source. |
| USBGuard | Disabled | Bad rules can block keyboards, mice, docks, and recovery devices. | Create a no-USBGuard boot specialization before enabling. |
| AIDE checks | Tool-only optional profile | Database churn is noisy on desktops and useless without persistence/update rites. | Design database paths, update command, and persistence before scheduling checks. |
| ClamAV scans | Tool-only optional profile | Daemons and broad scans can consume resources and create noisy logs. | Choose daemon or scheduled `clamscan`, not both by accident. |
| Flatpak browsers | Research only | Flatpak confinement and built-in browser sandboxes can trade strength in non-obvious ways. | Compare native and Flatpak variants with browser sandbox diagnostics before moving browsers into Flatpak. |
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
