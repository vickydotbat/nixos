# Home Modules

This tree declares reusable Home Manager mechanisms under `theorem.home.*`.

Home modules should provide shared working-surface mechanisms and conservative
defaults, not personal doctrine disguised as reusable code. Put broadly useful
shell integration, editor substrate, browser policy, persistence hooks, and
application wrappers here. Put one operator's theme, layout, shortcuts,
autostart habits, language stacks, and private workflow choices in
`users/<user>/`.

When a Home module depends on system substrate, make that dependency visible.
Examples include persistence, Podman or Distrobox support, SSH secret material,
desktop portals, and terminal key ownership. If the system side is absent, the
module should either remain quiet or fail with a clear boundary rather than
silently creating half a mechanism.

If a feature is absent from `users/<user>/profiles.nix`, check the reusable
module defaults before assuming it is dormant. Some substrates, such as fonts,
XDG directories, terminal integration, and persistence, may follow the features
they serve. Optional applications, games, backup jobs, hardware conveniences,
and compatibility layers should remain explicit choices in the user profile.

The repair rule is simple: a second user should be able to enable these modules
and receive plain tools, not Vicky's whole workshop by accident.
