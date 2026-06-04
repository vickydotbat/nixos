# Hardening Sysctl Quarantine

This note records the sysctl items that stay out of the conservative hardening
profile until a host proves it can carry them. The safe tier should be boring:
valid on the target kernel, low-breakage on desktops, and reversible through an
ordinary host override. Anything sharper belongs here first.

## Implemented Safe Tier

`modules/nixos/security/hardening.nix` currently owns only these conservative
families when `theorem.nixos.security.hardening.sysctl.safeDefaults.enable` is
selected:

- filesystem link-trap protections: `fs.protected_fifos`,
  `fs.protected_hardlinks`, `fs.protected_regular`, and
  `fs.protected_symlinks`
- kernel disclosure and debugging limits: `kernel.dmesg_restrict`,
  `kernel.kptr_restrict`, `kernel.randomize_va_space`, and
  `kernel.yama.ptrace_scope`
- common IPv4 redirect and source-route hardening for `all` and `default`
  interfaces
- common IPv6 redirect and source-route hardening for `all` and `default`
  interfaces

NixOS' upstream `security` module still owns related upstream defaults such as
`kernel.kexec_load_disabled`. Keep that boundary intact unless a later review
finds a real conflict.

## Quarantined Items

| Sysctl | Status | Why It Stays Out |
|---|---|---|
| `kernel.exec-shield` | rejected | Not present on the current Solanine kernel view and historically tied to older downstream kernel patchsets. Adding it would be cargo-cult failure, not hardening. |
| `net.ipv4.icmp_echo_ignore_all = 1` | quarantined | Blocks ping replies. That may be acceptable for a hidden appliance, but it breaks ordinary reachability checks and should not be a desktop or general server default. |
| `net.ipv6.conf.*.accept_ra = 0` | quarantined | Disables IPv6 router advertisements. That can break normal SLAAC networks, especially on laptops and desktops that move between networks. |
| `net.ipv4.conf.*.forwarding = 0` and `net.ipv6.conf.*.forwarding = 0` | host-owned | Forwarding is a routing role, not a generic hardening switch. Router, VPN, container, and lab hosts must declare their own posture. |
| `kernel.unprivileged_userns_clone = 0` | host-derived | Flatpak, rootless Podman, Chromium-family browser sandboxes, and some developer tooling need unprivileged user namespaces. The hardening module derives this from declared host features instead of forcing it off. |

## Validation Rite

Run these from the real NixOS host namespace after boot. A restricted tool
sandbox can expose only its own loopback network namespace, which is useful as a
smoke test but not proof for the whole machine.

```bash
sysctl -a 2>/dev/null | rg '^(fs\.protected_(fifos|hardlinks|regular|symlinks)|kernel\.(dmesg_restrict|kptr_restrict|randomize_va_space)|kernel\.yama\.ptrace_scope|net\.ipv4\.conf\.(all|default)\.(accept_redirects|accept_source_route|log_martians|secure_redirects|send_redirects)|net\.ipv6\.conf\.(all|default)\.(accept_redirects|accept_source_route))\s*='
```

```bash
sysctl -a 2>/dev/null | rg '^(kernel\.exec-shield|net\.ipv4\.icmp_echo_ignore_all|net\.ipv6\.conf\.(all|default)\.accept_ra|net\.(ipv4|ipv6)\.conf\.(all|default)\.forwarding|kernel\.unprivileged_userns_clone)\s*='
```

The first command should show the selected safe-tier keys and values. The
second command is a quarantine audit: it confirms which sharp keys exist on the
running kernel and whether any other module or service changed them after boot.

Failure modes to watch:

- generated `/etc/static/sysctl.d/60-nixos.conf` contains the intended value,
  but `/proc/sys/...` differs after boot; suspect a later network manager,
  container runtime, VPN, or interface-specific service
- `all` and `default` match, but a named interface differs; inspect the owner of
  that interface before forcing a global default
- a key is missing from `sysctl -a`; do not add it from an external guide until
  the target kernel proves it exists
