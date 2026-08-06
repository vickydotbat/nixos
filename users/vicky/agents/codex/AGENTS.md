## NixOS Environment

This machine runs NixOS. Do not assume generic Linux/FHS behavior.

Prefer repository-native commands and existing Nix entry points:

- `flake.nix`
- `shell.nix`
- `devenv.nix`
- `nix develop`
- `nix shell`
- `nix run`
- documented `just`, `make`, package-manager, or test commands

Do not use `apt`, `dnf`, `pacman`, Homebrew, global `pip install`, global `npm install`, or curl-pipe installers unless explicitly asked.

Do not use `sudo`. If privileged access is explicitly required and approved, use `run0`.

Do not start long-running services, containers, model pulls, network waits, or user systemd units from Home Manager activation hooks.

If a repo lacks `flake.nix`, `shell.nix`, or `devenv.nix`, first prefer transient `nix shell` / `nix develop` usage. Create a minimal dev shell or flake only when the task requires reproducible repo-local tooling or the user asks for it.

# Global Agent Instructions

These instructions apply to all repository work unless a local repository instruction is stricter.

## Instruction Authority

Follow instructions in this order:

1. System/developer/user instructions from the active conversation.
2. Local repository instructions, especially the nearest applicable `AGENTS.md`.
3. This global `AGENTS.md`.
4. Workflow skills and package guidance.
5. General model knowledge.

If instructions conflict, stop and ask unless the higher-priority instruction clearly resolves the conflict.

## Default Workflow Layers

Use installed workflow skills when appropriate.

Bigpowers is the default workflow layer for non-trivial repository work: discovery, planning, slicing, implementation, verification, audit, and review.

Ponytail is the default restraint layer for implementation and review: keep changes small, prefer native/simple solutions, avoid speculative abstractions, and verify behavior.

Do not use Ponytail to reject intentionally chosen Bigpowers workflow artifacts such as plans, specs, review notes, or documentation updates.

For trivial tasks, do not over-process. Make the smallest safe change and verify it.

## Mandatory Context Gate

Before modifying files in a repository, produce a **Context Receipt**.

Do not edit files until the Context Receipt is complete.

The Context Receipt must include:

1. **Task understood**: what the user asked for.
2. **Likely touched paths**: files/directories expected to be edited.
3. **Context read**:
   - this global `AGENTS.md`
   - the repository root `AGENTS.md`, if present
   - any nearer `AGENTS.md` files for paths likely to be touched
   - `CLAUDE.md`, `CONVENTIONS.md`, README files, docs indexes, plans, specs, or dev-shell files that the repository marks as relevant
   - any task-specific files named by the user

4. **Applicable rules**: the rules that constrain this task.
5. **Branch/status**: current branch and `git status --short --branch`.
6. **Verification plan**: the first check, test, or command expected to validate the work.
7. **Uncertainties/blockers**: anything missing, stale, contradictory, unsafe, or unclear.

If the task is read-only, the Context Receipt may be brief.

If the task is urgent or very small, still produce a compact Context Receipt before editing.

If a required context file is missing, stale, contradictory, or too large to inspect safely, stop and ask.

## Repository Locality

Before editing a file, check whether a nearer `AGENTS.md` applies to that path.

Nearest local instructions may add path-specific rules, but they must not weaken safety rules from higher-priority instructions.

Do not assume rules from one subsystem apply to another. Re-check locality when crossing boundaries such as:

- frontend/backend
- packages/modules
- tests
- tools/scripts
- migrations
- infrastructure/Nix/dev-shell files
- generated assets
- documentation trees

## Repository Safety

Before editing a repository:

1. Read applicable instructions.
2. Run `git status --short --branch`.
3. Identify the current branch.
4. Identify unrelated user changes.
5. Avoid touching unrelated files.

Do not commit unless explicitly asked.

Never commit to `main` or `master`.

Never force-push.

Never run destructive commands such as `git reset --hard`, `git clean`, deleting branches, wiping files, or rewriting history unless explicitly asked.

Reuse the current feature branch unless the user asks for a new one.

Do not create stacked branches unless explicitly asked.

Do not overwrite, revert, reformat, or “clean up” user changes unless the user explicitly asks.

If unrelated changes are present, preserve them and mention them.

## Scope Discipline

Keep changes narrowly scoped to the requested task.

Do not perform opportunistic refactors.

Do not upgrade dependencies, rewrite architecture, rename public APIs, move large file trees, alter formatting globally, or change generated files unless the task requires it.

Ask before making decisions that affect scope, safety, architecture, data, migrations, deployment, or compatibility.

Prefer the simplest working solution.

Flag uncertainty instead of guessing.

## NixOS and Environment Assumptions

Assume repositories may be used on NixOS.

Do not assume generic Linux/FHS package availability.

Prefer existing dev shells, flakes, package scripts, or documented commands.

If dependencies are missing, use a dev shell or propose a flake/dev-shell change rather than installing ad hoc global packages.

Do not add Home Manager activation hooks that start long-running services, containers, model pulls, network waits, or repo orchestration.

Declarative configuration should create or enable services, not synchronously start heavyweight processes during activation.

## Secrets and Sensitive Files

Do not read, print, modify, copy, move, or commit secrets, credentials, tokens, private keys, `.env` contents, `.sops` data, authentication files, or production credentials unless explicitly instructed.

If a command may expose secrets, do not run it.

If a file appears sensitive after opening it accidentally, stop reading and report that it was avoided.

## Testing and Verification

Test behavior and public contracts, not implementation details.

Avoid brittle tests that assert arbitrary dictionary values, incidental wording, internal ordering, generated text, snapshots, or implementation structure unless those are the public contract.

Prefer tests that would catch real regressions.

For non-trivial code changes, run at least one relevant check.

If checks cannot be run, say exactly what was not run and why.

Do not claim success without verification.

## Documentation Updates

Update documentation only when the change affects durable knowledge, such as:

- setup commands
- test commands
- architecture boundaries
- workflow rules
- generated-file rules
- public behavior
- package ownership
- local gotchas
- operational or deployment steps

Do not update docs just to show activity.

Prefer short, local, accurate documentation over broad rewrites.

Mark stale docs as stale instead of deleting them unless deletion is explicitly approved.

## AGENTS.md Maintenance

Do not create `AGENTS.md` in every folder by default.

Create or update local `AGENTS.md` files only at meaningful boundaries where path-specific rules help future agents.

A local `AGENTS.md` should be short and operational. It should not duplicate root rules unless the duplication is needed for safety.

Good local `AGENTS.md` content includes:

- local setup/test commands
- files that are generated or should not be edited
- subsystem boundaries
- ownership or review expectations
- common local failure modes
- path-specific constraints

## Planning Expectations

For multi-step work, create or update a short plan before editing.

The plan should include:

1. What will change.
2. What will not change.
3. Files or areas likely to be touched.
4. Risks and unknowns.
5. Verification steps.

For larger work, stop after the plan and wait for approval unless the user already approved implementation.

## Work Completion

Before final response or commit request:

1. Review the diff.
2. Confirm scope stayed narrow.
3. Run relevant verification or explain why not.
4. Mention docs updated or explain why no durable documentation change was needed.
5. Summarize changed files.
6. Call out unresolved risks or follow-up work.

Do not hide failures, skipped tests, uncertainty, or partial completion.
