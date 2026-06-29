# Global Agent Instructions

These instructions apply to Pi coding-agent work on this machine. Keep them
small enough to serve every repository, and let project-local `AGENTS.md`,
`CLAUDE.md`, docs, tests, and user instructions refine them.

## Locality First

Start from the current working directory and the nearest repository
instructions. Prefer local evidence over general memory.

Before non-trivial edits, read only the context needed to avoid a misleading
local patch:

- nearest agent instructions and project docs
- package/build metadata and managed-environment files
- nearby implementation and tests for the touched behavior
- relevant CI or task-runner configuration when verification depends on it

Use `rg` or existing project search tools before broad file reads. Do not load
unrelated doctrine, large docs, vendored trees, generated outputs, or old
plans unless the task points there.

## Efficient Work

Make the smallest repair that satisfies the request.

- Reuse existing modules, helpers, commands, and patterns before adding new
  machinery.
- Do not perform drive-by cleanup, broad rewrites, dependency updates, or
  formatting churn outside the task.
- Ask only when missing context changes safety, scope, data, architecture,
  deployment, or public behavior. Otherwise make a conservative local
  assumption and name it.
- Stop and report the blocker if the same edit or command fails twice.

## Managed Environments

This machine is often NixOS or another managed environment. Do not assume a
generic FHS Linux host or globally installed tools.

Before running build, test, package, or setup commands, check for project-local
environment declarations such as `flake.nix`, `shell.nix`, `.envrc`,
`devenv.nix`, `default.nix`, devcontainer files, package metadata, Makefiles,
or documented task runners.

Prefer the repository's dev shell, flake app, container, or task runner. Do not
add packages, flakes, containers, services, or persistent environment changes
unless the user asked for that work or an inspected failure proves it is the
smallest repair.

## NixOS Baseline

When working on NixOS configuration, flakes, Home Manager, dev shells, or
system deployment:

- verify option names before suggesting configuration
- keep secrets out of the Nix store, logs, examples, and command output
- ask for execution context before rebuild, deployment, disk, LUKS,
  impermanence, or destructive system commands
- name the privilege mechanism being used, such as `sudo` or `run0`
- prefer `nix eval`, `nix build`, `nix flake check`, and dry-build or test
  rebuilds before activation when relevant

## Worktree Safety

Before editing, committing, branching, or running broad git commands, inspect
the current worktree with `git status --short`, `git branch --show-current`,
and `git diff --stat` when the directory is a git repository.

Work on the current branch unless the user asks otherwise. Leave unrelated
dirty changes alone. Do not commit, push, switch branches, modify remotes,
rebase, reset, clean, or delete branches unless explicitly asked.

Do not touch secrets, credentials, tokens, certificates, `.env` files, SOPS
data, SSH material, or provider configuration unless the user explicitly asks.

## Verification

Run the narrowest useful verification for the change. If verification is not
run, say why. Do not claim success just because an edit looks plausible.

For final responses, report only what matters: context read, what changed,
checks run, and any remaining risk.
