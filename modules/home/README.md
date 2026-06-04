# Home Modules

This tree declares reusable Home Manager mechanisms under `theorem.home.*`.

Apply [`docs/philosophy.md`](../../docs/philosophy.md) here as Home doctrine:
shared Home modules should provide reusable mechanisms, not one operator's
private working surface by accident.

## External Home Flakes

User-owned Home flakes may import this repository's shared Home baseline through
`inputs.<this-flake>.homeModules.shared`. That export injects the ordinary
module arguments expected by this tree and imports the reusable Home modules
without selecting any host, login account, SOPS identity, or Vicky profile.

The export is a mechanism library, not a trust gate into the system theorem. A
personal Home flake that consumes it still owns its applications, themes, shell
habits, editor posture, and activation command from the user's directory. If a
host later imports user-owned Home code during `nixos-rebuild`, that is a
separate root-affecting decision and must be declared by a repository steward.

`checks/home-shared-boundary.nix` is the standing proof for this boundary. It
builds a synthetic Home profile from `homeModules.shared` with no NixOS
`osConfig`, no Impermanence Home option provider, no Plasma Manager provider,
and no `users/vicky` imports. Keep it passing when adding shared modules.

Home modules should provide shared working-surface mechanisms and conservative
defaults, not personal doctrine disguised as reusable code. Put broadly useful
shell integration, editor substrate, browser policy, persistence hooks, and
application wrappers here. Put one operator's theme, layout, shortcuts,
autostart habits, language stacks, and private workflow choices in
`users/<user>/`.

When a Home module depends on system substrate, make that dependency visible.
Examples include persistence, Podman or Distrobox support, desktop portals, and
terminal key ownership. If the system side is absent, the module should either
remain quiet or fail with a clear boundary rather than silently creating half a
mechanism.

Per-user SSH identity is a deliberately narrower case. `theorem.home.base.ssh`
restores SOPS-backed key material for outbound SSH, Git remotes, and Git
signing. That mechanism needs declared secret material, but it does not require
the system OpenSSH server. Keep inbound `sshd`, host keys, firewall exposure,
and remote-login posture under `theorem.nixos.base.ssh`; keep user identity and
agent ownership under Home Manager.

If a feature is absent from `users/<user>/profiles.nix`, check the reusable
module defaults before assuming it is dormant. Some substrates, such as fonts,
XDG directories, terminal integration, and persistence, may follow the features
they serve. Optional applications, games, backup jobs, hardware conveniences,
and compatibility layers should remain explicit choices in the user profile.

The repair rule is simple: a second user should be able to enable these modules
and receive plain tools, not Vicky's whole workshop by accident.
