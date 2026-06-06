# Repository Philosophy

This document is the heart of the repository. If a module, host profile, user
profile, package, plan, or agent suggestion does not serve this doctrine, change
the shape of the work until it does. The theorem should become more reliable,
more legible, and easier to repair with time; drift in the other direction is a
regression even when `nix flake check` is green.

`docs/TODO.md` is a repair ledger. This file is the standard that ledger must
serve.

## Purpose

This repository declares a NixOS configuration system that is reliable,
understandable, portable, and safe to evolve. A fresh clone, the required
secrets, and declared host facts should be enough to rebuild a host without
relying on remembered commands, hand-edited state, or one operator's private
habits.

The repository is allowed to be opinionated. It is not allowed to be mysterious.
Every durable mechanism should make clear what it protects, what it assumes,
what can break, and how a tired maintainer proves or reverses it.

## Non-Negotiable Laws

### Reproducibility, Always

Every meaningful behavior should be reproducible from checked-in configuration,
tracked encrypted secrets, and documented installation or recovery rites. Prefer
declarative Nix configuration over imperative setup. When an imperative step is
unavoidable, keep it narrow, name the authority it needs, and document the
validation command beside it.

Untracked local state may be useful during repair. It must not become part of
the system's memory.

### Determinism In Every Shape

The same inputs should produce the same outputs. Do not let ambient machine
state decide security posture, persistence, boot behavior, networking, shell
behavior, or user data. If behavior differs by host, model that difference as
host data or a host module. If behavior differs by user, put it in the selected
user profile or a user-owned Home flake.

Hidden discovery is not flexibility. It is an undocumented dependency waiting
for the next rebuild to expose it.

### Explicit Host And User Boundaries

This repository must support multiple hosts with different hardware, users,
roles, and risk levels. A laptop, desktop, server, VM, gaming machine,
development workstation, or rescue system should not inherit irrelevant
assumptions from another host.

Use the lanes deliberately:

- `hosts/<host>/` owns host identity, hardware facts, disk layout, boot posture,
  and one-off host decisions.
- `modules/nixos/` owns reusable root-controlled mechanisms under
  `theorem.nixos.*`.
- `modules/home/` owns reusable Home Manager mechanisms under `theorem.home.*`.
- `users/<user>/` owns the selected user's working surface: themes, editor
  posture, shell habits, autostart choices, language stacks, and private
  workflow calibration.
- `pkgs/` owns local package recipes; modules and profiles decide whether those
  recipes are installed.

If a reusable module starts carrying Vicky's personal workshop, split it or move
that choice back to `users/vicky/`. If a host profile grows a reusable
mechanism, extract it into a module with a clear option surface.

### Solid Defaults, Not A Cage

Modules should be useful when enabled with minimal configuration, but defaults
must remain replaceable unless there is a deliberate safety reason. Use
`lib.mkDefault` for defaults meant to be overridden. Use `lib.mkForce` only
when the module is intentionally enforcing a boundary and the reason is visible
near the code.

When defaulting a nested configuration set, default the leaves and combine
fragments with `lib.mkMerge`. Do not wrap a whole attrset in `lib.mkDefault`
when another user, host, or profile may set one child beneath it. That shape can
silently discard sibling defaults such as safety checks, persistence hooks, or
trust declarations. The correct repair is a mergeable mechanism, not a sharper
override.

Vicky's defaults are field-tested notes, not universal law. Preserve what is
broadly useful; keep personal doctrine out of shared mechanisms.

### Minimum Practical Hardening

Hardening is calibrated stewardship, not a pile of switches. Start each security
mechanism with the threat it answers, the workflow it can break, the recovery
path, and the command or boot test that proves it still serves the host.

A setting that breaks login, rollback, networking, containers, browser work,
desktop portals, development tools, or emergency debugging needs a clear reason
and a visible escape hatch. Prefer incremental, documented hardening over broad
opaque restriction blocks.

Sharp profiles belong behind explicit host selection, compatibility notes, and
rollback rites. Security theatre is still technical debt.

### No Hidden Privilege Expansion

Groups, sockets, secrets, and imported code are authority surfaces. They must be
owned by the mechanism that requires them and granted only to the users or hosts
that accept the risk.

Repository stewardship is not personal Home ownership. Membership in the
repository group means "may repair this NixOS theorem". It should not be the
price of owning a personal Home Manager repository.

Do not auto-discover user-writable Nix into a system rebuild. If the system
flake imports user-owned Home code, a repository steward must declare that trust
gate explicitly and review the path as root-affecting configuration.

### Secrets Stay Out Of The Store

Secret material belongs in SOPS-managed files and runtime secret paths, not in
Nix strings, generated derivations, package recipes, logs, or copied examples.
Distinguish identity classes: SOPS age keys decrypt repository secrets; host SSH
keys identify inbound servers; user SSH keys identify outbound users and Git
signing. One name, one authority, one recovery rite.

A secret mechanism is not complete until its creation rule, runtime owner, mode,
consumer, and recovery path are visible.

### Modularity With Clear Edges

Each module should name one repairable mechanism, expose the smallest useful
interface, and remain quiet until selected or until it is a true substrate for a
selected feature. Enabling one module must not unexpectedly configure unrelated
features.

Derived defaults are acceptable where the dependency is real: fonts or XDG
support following graphical tools, Home persistence following system
persistence, graphics and audio following a selected desktop or gaming profile.
Optional applications, games, backup jobs, hardware conveniences, browser
choices, and compatibility layers remain explicit selections.

If a mechanism cannot be understood without reading three unrelated files, the
boundary needs repair.

### Avoid Over-Engineering

Simplicity and ease of use win unless abstraction pays rent. Do not introduce a
framework, generator, helper library, custom DSL, or deep option hierarchy just
to avoid a small amount of repetition. Repetition is acceptable when it keeps
intent clear.

Add abstraction when it removes real duplication, prevents mistakes, or makes
host variation easier to reason about. If the abstraction hides authority,
state, or failure modes, it is the wrong abstraction.

### Documentation Beside Mechanisms

Documentation is part of the mechanism. Every module should carry a purpose
block or option descriptions that explain why it exists and what breaks when it
is mishandled. Wider behavior belongs in directory `README.md` files or focused
documents under `docs/`.

Do not leave doctrine trapped in TODO comments, plan files, or incident notes.
When a task crystallizes a rule, promote the rule to the place future hands will
read before making the next change.

### Verification Before Trust

For NixOS work, prefer targeted `nix eval`, `nixfmt --check`, `nix flake check`,
and `nixos-rebuild dry-build` before switching. For risky host work, name the
execution context first: local NixOS host, remote NixOS target, macOS driving a
remote rebuild, CI, installer, or another crucible.

A change is not repaired because it is plausible. It is repaired when the right
validation rite has passed and the rollback path is known.

## Structural Doctrine

### Dendritic Nix

The dendritic pattern treats most Nix files as modules of the top-level
configuration, allowing a feature to branch naturally across NixOS, Home
Manager, packages, dev shells, overlays, and other flake outputs. Use it when it
keeps related mechanism close and reduces cross-file scattering.

Do not use dendritic shape as permission to make the repository surprising. A
human reader should still be able to predict which files are imported and which
configuration surface they affect.

### `import-tree`

`import-tree` makes recursive module discovery less manual and helps the tree
scale without long import lists. In this repository that convenience is sharp:
every `.nix` file under an imported module tree is part of evaluation.

Therefore imported module trees must stay predictable. Files should expose
options and remain quiet until selected. Avoid aggregator files that duplicate
recursive imports, hidden side effects, and modules whose filenames do not
match their authority.

### `flake-parts`

`flake-parts` is a possible future repair if the flake itself becomes a large
coordination layer for packages, checks, dev shells, formatters, overlays, and
host outputs. It should be adopted only if it makes those surfaces clearer.

Do not migrate to `flake-parts` as fashion. The current handwritten `outputs`
function is acceptable while it remains understandable. If that stops being
true, make the change deliberately and document the new boundary.

## Core Substrates

### Home Manager

Home Manager keeps user packages, dotfiles, shell tools, editor settings, and
desktop preferences declarative beside the system configuration. Use it for
user environments and working surfaces. Do not put host hardware, boot, or
system service policy into Home Manager unless the boundary is deliberately
chosen and documented.

The useful split is two-lane: the system flake provides login accounts, groups,
persistence substrate, shared modules, and safe defaults; Home profiles or
user-owned Home flakes provide personal applications, themes, shell habits,
editor posture, and private workflow choices.

### Impermanence

Impermanence is a discipline mechanism as much as a storage mechanism. On
ephemeral-root systems, undeclared state is discarded, so accidental setup and
hidden persistence become visible quickly. Use it carefully: persistence lists
should be intentional, minimal, and documented where the reason is not obvious.

State that must survive belongs in declared persistence paths. State that cannot
be explained should probably not survive.

### `sops-nix`

`sops-nix` is the repository secret substrate. It lets encrypted files remain in
Git while provisioning runtime secrets declaratively. Use it for host keys, user
SSH material, service credentials, tokens, and other sensitive state needed at
activation time.

Add creation rules before creating a new class of secret. Add encrypted files to
Git before evaluating flakes that reference them. Never confuse encrypted-at-rest
with safe-to-log, safe-to-copy, or high entropy.

### `treefmt-nix`

`treefmt-nix` is appropriate when formatting should become part of the flake
rather than a local editor habit. Use it when it gives maintainers and agents a
shared formatting rite across languages. Avoid formatters that create noisy
churn without improving review, repair, or determinism.

### `flake-utils`

`flake-utils` is a small helper for common flake patterns, especially
multi-system output generation. It is acceptable for simple flakes or narrow
helpers. In a NixOS theorem, prefer whichever approach keeps host handling,
system lists, and output ownership explicit to a human reader.

## Research Handles

These are research handles, not automatic imports. Read, compare, and adapt only
what survives this repository doctrine.

- Dendritic Nix: <https://github.com/mightyiam/dendritic>
- `import-tree`: <https://github.com/vic/import-tree>
- `flake-parts`: <https://github.com/hercules-ci/flake-parts>
- `flake-parts` docs: <https://flake.parts/>
- `flake-utils`: <https://github.com/numtide/flake-utils>
- Home Manager: <https://github.com/nix-community/home-manager>
- Impermanence: <https://github.com/nix-community/impermanence>
- `sops-nix`: <https://github.com/Mic92/sops-nix>
- `treefmt-nix`: <https://github.com/numtide/treefmt-nix>

## Change Gate

Before adding or changing a mechanism, answer these questions:

1. Is this behavior reproducible from the repository, declared secrets, and host
   facts?
2. Is every host or user difference modeled explicitly?
3. Does the mechanism belong in `hosts/`, `modules/nixos/`, `modules/home/`,
   `users/`, `pkgs/`, or `docs/`?
4. Is the default useful without becoming a cage?
5. What authority does it grant: group, socket, secret, service, filesystem
   path, network path, imported code, or browser/desktop surface?
6. What workflow can it break, and how does the operator recover?
7. What command, build, boot, login, or activation test proves it?
8. If the current repository shape fights the answer, what shape must change?

If these questions expose a mismatch, repair the shape before piling more
configuration on top. The repository is a theorem, not a drawer.
