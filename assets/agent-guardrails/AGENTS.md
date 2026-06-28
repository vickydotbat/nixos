# Agent Instructions

These instructions apply to AI coding agents working in this repository. They are intentionally generic and should be refined by project-specific documentation when available.

Prefer repository-local instructions, existing documentation, package metadata, build files, CI configuration, and nearby code over assumptions. When instructions conflict, follow the more specific and safer instruction. If ambiguity affects scope, safety, data, architecture, deployment, concurrency, or public behavior, stop and ask.

## Core Contract

Do not treat implementation as a local text transformation. Treat every change as a responsibility-preserving change inside an existing system.

Before non-trivial implementation, prove that you understand the relevant system shape:

- what the subsystem is responsible for
- where the changed concepts belong
- what existing infrastructure already solves nearby problems
- what workflows already depend on the touched code
- what concurrency, lifecycle, data, deployment, security, or public-contract assumptions apply

If you cannot establish those facts from repository docs, nearby code, tests, and configuration, stop and ask before editing.

## Mandatory Context Gate

For any non-trivial task, do not edit until you have completed a context pass.

A task is non-trivial if it touches or may affect:

- architecture or responsibility boundaries
- public behavior, public APIs, commands, events, protocols, or configuration
- async, threading, workers, queues, lifecycle, cancellation, or shared state
- data, migrations, persistence, caching, consistency, or idempotency
- security, privacy, permissions, authentication, secrets, or tokens
- deployment, CI, build tooling, packages, services, or infrastructure
- tests for behavior that may be coupled to implementation details
- unfamiliar code or a subsystem with repository documentation

During the context pass, identify and read relevant sources:

- `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, `.github/copilot-instructions.md`, or other agent/developer instructions
- `README`, `CONTRIBUTING`, setup docs, and developer docs
- `docs/`, `documentation/`, `architecture/`, `design/`, `adr/`, `notes/`, wiki exports, or subsystem docs
- package/build metadata and task runner configuration
- CI workflows and test configuration
- nearby implementation files
- existing tests for the touched behavior
- recent related commits when useful

Search for task terms and architectural terms. Depending on the task, include terms such as:

- feature, module, class, function, command, setting, option, event, handler, interface, or config names
- domain terms used by the project
- public API names and error messages
- `thread`, `async`, `await`, `lock`, `mutex`, `queue`, `worker`, `parallel`, `task`, `scheduler`, `cancellation`, `timeout`, `race`, `deadlock`, `lifecycle`, `startup`, `shutdown`, `readiness`
- `transaction`, `migration`, `consistency`, `idempotent`, `retry`, `cache`, `persistence`
- `auth`, `permission`, `secret`, `token`, `credential`, `role`, `policy`

Before editing, report:

- docs and files read
- relevant constraints discovered
- existing patterns or canonical infrastructure to reuse
- workflows that may be affected
- likely files to change
- uncertainty or missing context

Do not proceed if missing context could affect correctness, safety, architecture, data, concurrency, deployment, or public behavior.

## Environment

This machine may use NixOS or another managed development environment.

- Avoid generic Linux and FHS assumptions.
- Do not assume globally installed tools are available.
- Inspect the repository before choosing commands or dependencies.
- Use existing dev shells, flakes, containers, task runners, or repo-provided tooling when available.
- If dependencies are missing, prefer entering an existing managed environment over installing ad hoc tools.
- Do not add a new flake, dev shell, container, dependency, service, or module unless necessary for the requested task.

Look for:

- `README`, `CONTRIBUTING`, or project docs
- package/build metadata
- lockfiles
- `Makefile`, task runner config, or scripts
- `flake.nix`, shell files, devcontainer files, or container config
- CI workflows
- test configuration
- existing agent instructions

Use documented commands. If commands are missing, infer carefully from nearby files and state the inference.

## Operating Principles

- Prefer the simplest working solution.
- Make the smallest safe change that satisfies the task.
- Try no-code, config-only, deletion-only, or minimal-edit solutions before adding new code.
- Do not broaden scope without asking.
- Do not touch unrelated code.
- Flag uncertainty instead of guessing.
- Read before editing.
- Preserve existing style, architecture, naming, and file organization unless the task explicitly asks to change them.
- Do not add abstractions, helpers, dependencies, files, services, or modules unless necessary.
- Treat generated files, lockfiles, migrations, snapshots, vendored files, and build artifacts as high-risk unless the task specifically involves them.
- Do not claim success unless checks were run, or clearly explain why checks were not run.

## Architecture and Responsibility Rules

Names, folders, interfaces, and files must tell the truth about current responsibility.

Before adding, moving, or converting a type, service, adapter, handler, stage, workflow, or domain object, establish where it belongs in the existing architecture.

Rules:

- Keep concepts in the folder or module that owns them.
- Domain data and rules belong in domain areas.
- Adapters and integration code belong in adapter/integration areas.
- Pipeline stages belong with the pipeline feature that owns them.
- If a class stops being responsible for what its name or folder says, rename or move it in the same change.
- Do not leave converted code in its old location just because that is where it started.
- Do not create a new local mechanism when an existing service-level or framework-level mechanism already exists.
- Do not add compatibility shims, fallbacks, duplicate settings, or lifecycle workarounds without a current verified requirement.

Before adding a new safety mechanism, fallback, readiness check, retry, cache, lock, queue, scheduler, registry, or lifecycle hook, search for the canonical existing mechanism and reuse it when appropriate.

If the existing mechanism is insufficient, explain why before adding a new one.

## Scope and Refactor Discipline

Keep feature work narrow.

- Do not mix broad refactors into feature PRs unless the feature requires them.
- If a feature requires a refactor, keep the refactor focused on the feature path.
- Do not perform drive-by cleanup, formatting, renames, or restructuring outside the requested scope.
- If touching shared infrastructure, identify the old workflows that depend on it and verify the important ones still work.
- If a change affects command dispatch, startup, readiness, pipelines, adapters, serialization, permissions, migrations, background workers, or shared services, assume existing workflows may be affected until checked.

## Anti-Speculation Rules

Do not add code for hypothetical future requirements.

Avoid speculative:

- abstractions
- configuration
- extension points
- locks
- retries
- fallbacks
- compatibility layers
- local safety mechanisms
- duplicate canonical IDs or settings
- future-proofing branches

A safety mechanism must have a current failure mode. An abstraction must have a current caller or clear current simplification. Configuration must correspond to a real deployment or user need.

If a value is canonical in one source, do not duplicate it in settings unless the repository already uses that pattern or the task requires it.

If a collection is built once during startup and is never mutated afterward, do not add read locks for hypothetical future mutation.

Promote repeated magic literals to a named constant near the top of the class or module when doing so improves clarity without broadening scope.

## Approval Required

Ask before making decisions that affect:

- scope
- architecture
- data or migrations
- security or privacy
- concurrency, threading, lifecycle, or readiness behavior
- deployment
- public behavior
- public APIs or contracts
- dependency choices
- irreversible operations
- large rewrites
- deleting files
- generated or vendored code
- remotes, branches, PRs, releases, or CI configuration

## Hard Safety Rules

- Do not run destructive commands unless explicitly asked.
- Do not use `rm -rf`, destructive `git` operations, mass deletion, database resets, or cleanup scripts without explicit approval.
- Do not touch secrets, credentials, keys, tokens, certificates, `.env` files, `.sops` data, production configuration values, or secret-management files unless explicitly asked.
- Do not print, cat, echo, copy, commit, summarize, or expose secret values.
- Do not commit unless explicitly asked.
- Do not push unless explicitly asked.
- Do not open PRs unless explicitly asked.
- Do not delete branches unless explicitly asked.
- Do not modify remotes unless explicitly asked.
- Never force-push unless explicitly asked and the exact branch has been confirmed.
- Never commit directly to `main`, `master`, or a protected release branch unless explicitly instructed.

## Worktree and Branching Rules

Before editing, branching, committing, switching branches, or running broad commands, inspect:

```bash
git status --short
git branch --show-current
git diff --stat
```

When relevant, also inspect:

```bash
git diff --name-only
git log --oneline -5
```

Rules:

- Reuse the current feature branch only when it is clean and clearly related to the requested task.
- If unrelated dirty changes exist, stop and ask.
- Before creating a new branch, check the current branch.
- New branches should start from up-to-date `main` or the repository's configured base branch, not from another feature branch.
- Do not create stacked branches unless explicitly asked.
- Do not reuse a branch that was merged remotely and deleted unless explicitly asked.
- Keep user changes separate from agent changes.
- Keep commits focused when commits are explicitly requested.
- Do not mix unrelated changes in one commit.

## Dependency Rules

- Do not add dependencies casually.
- Prefer the standard library and existing project dependencies.
- Ask before adding runtime dependencies.
- For dev-only dependencies, explain why existing tooling is insufficient.
- Do not update lockfiles unless the task requires it or the package manager does so as part of the requested change.
- Do not perform broad package upgrades unless explicitly asked.
- Do not change dependency managers, build systems, or environment tooling without approval.

## Concurrency and Async Rules

Treat concurrency, threading, async execution, scheduling, cancellation, readiness, shutdown, and shared mutable state as high-risk.

Before changing code that may run concurrently, read relevant architecture docs, nearby implementation, and tests.

If you are unsure whether code is single-threaded, assume it may be concurrent and investigate before editing.

Do not introduce sync-over-async or blocking waits in async/concurrent/server code unless the existing architecture explicitly allows it and you can explain why it is safe.

Avoid:

- blocking on async work with `.Result`, `.Wait()`, `GetAwaiter().GetResult()`, or equivalent
- blocking an event loop or worker path
- sleeping instead of awaiting or using proper synchronization
- fire-and-forget tasks without ownership, logging, cancellation, and error handling
- shared mutable state without synchronization or immutability
- lock ordering changes without understanding deadlock risk
- global/static mutable state in request, worker, plugin, or server code
- swallowing task/thread exceptions
- ignoring cancellation tokens, timeouts, shutdown paths, or readiness flows
- local lifecycle/readiness fallbacks when canonical infrastructure exists

When touching concurrent code, verify:

- async boundaries are preserved
- cancellation and shutdown behavior are respected
- exceptions are observed and handled
- shared state is protected or avoided
- ordering assumptions are documented or tested
- tests do not rely on timing unless unavoidable

## C# and .NET Hygiene

Apply these rules when working in C#/.NET repositories.

File and type layout:

- Use one public top-level type per file.
- Interfaces always get their own file named after the interface, such as `IFooService.cs`.
- Public records, classes, enums, and structs get their own files.
- Do not put public interfaces, records, classes, enums, or structs at the bottom of service files.
- If a helper type is used by exactly one class, make it private/nested and put it at the bottom of that class.
- If another file needs the helper type, it is no longer private and must move to its own file.

Responsibility and placement:

- Keep type placement honest: domain records in domain folders, adapters in adapter folders, and pipeline stages inside the pipeline feature folder that owns them.
- Do not leave converted stages in their old service folder.
- If a refactor changes what a service is responsible for, rename or move the service so the name still tells the truth.

Async and lifecycle:

- Never use sync-over-async in server paths: no `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`.
- Prefer async all the way through existing async call chains.
- Respect cancellation tokens, readiness services, startup/shutdown flows, and existing lifecycle infrastructure.
- Reuse existing lifecycle/readiness infrastructure instead of building local migration/readiness fallbacks.

Testing and API shape:

- Do not add production methods, constructors, switches, or visibility solely for tests.
- Tests should use real public behavior.
- If behavior is too engine-bound to test directly, extract a real pure rule or accept manual verification for that path.

Speculation and literals:

- Avoid speculative safety code.
- Do not add locks around immutable startup data.
- Do not duplicate canonical IDs in settings unless required by current behavior.
- Do not add future-proofing without a current requirement.
- Promote repeated magic literals to a named `const` near the top of the class.

## Testing Rules

Tests should catch real regressions.

Prefer tests that verify:

- behavior
- public contracts
- invariants
- error handling
- important integration points
- previously observed regressions
- concurrency, cancellation, lifecycle, and error paths when relevant

Avoid tests that freeze:

- implementation details
- private helper behavior unless the helper is itself the public unit under test
- exact wording that may legitimately change
- incidental ordering
- variable names
- harmless constants
- mutable configuration values
- generated text or snapshots that are not the feature under test
- dictionary/configuration values unless those exact values are the intended public behavior

When changing tests:

- Do not weaken tests just to make them pass.
- Explain why any removed or relaxed assertion was brittle, incorrect, redundant, or no longer applicable.
- Add regression coverage for bug fixes when practical.
- Prefer focused behavior tests over broad snapshots.
- Do not write tests merely to increase coverage.
- Do not add production API surface only to make tests easier.
- If tests cannot be run, explain why and state the most relevant command to run next.

## Documentation Rules

Update documentation when behavior, setup, commands, public APIs, configuration, workflows, architecture, or concurrency assumptions change.

Do not update documentation for purely internal refactors unless the docs would otherwise become misleading.

When docs and code disagree:

1. Inspect the code.
2. Inspect tests and CI.
3. Inspect recent related changes.
4. Decide which source is authoritative, or ask if the decision affects public behavior, architecture, safety, data, deployment, or concurrency.

Do not invent documentation for behavior you have not verified.

## Edit Discipline

- Read files before editing them.
- Prefer direct, targeted edits.
- Do not use broad Python, `sed`, `awk`, `perl`, or heredoc rewrites unless the task clearly requires it.
- Do not perform drive-by formatting or cleanup outside the requested scope.
- Do not reformat entire files unless formatting is the requested task.
- If the same edit fails twice, stop and report the blocker.
- Inspect the final diff before summarizing.
- Keep generated or machine-written changes minimal and reviewable.

## Implementation Workflow

For non-trivial tasks:

1. Inspect current git state.
2. Identify and read relevant repository instructions, docs, code, tests, and configuration.
3. Summarize the goal, constraints, relevant architectural findings, canonical mechanisms, and affected workflows.
4. Identify the minimal files likely to change.
5. Propose a short plan.
6. Make focused edits.
7. Run the most relevant checks.
8. Inspect the final diff.
9. Summarize the diff, checks, and residual risks.

For small obvious tasks, act directly but still stay within scope. If the task touches architecture, concurrency, data, deployment, security, public behavior, dependencies, or shared infrastructure, it is not a small obvious task.

## Review Workflow

When reviewing a diff or preparing a branch for PR, first read the relevant repository context. Do not review only the changed lines if architecture, threading, data flow, public behavior, lifecycle, or security could be affected.

Check for:

- conflicts with repository documentation or architecture rules
- incorrect assumptions about threading, async behavior, lifecycle, readiness, ownership, or responsibility
- names, folders, interfaces, or docs that no longer tell the truth
- local mechanisms that duplicate canonical infrastructure
- speculative safety code, configuration, locks, or future-proofing
- production API surface added only for tests
- old workflows that were not verified after shared infrastructure changed
- scope creep
- unrelated files
- brittle tests
- missing tests
- missing docs
- inconsistent naming or style
- dead code
- needless abstractions
- duplicated logic
- error handling gaps
- security or privacy risks
- migration or compatibility risks
- dependency or lockfile noise
- generated file noise
- CI failures or missing verification

Prefer concrete findings with file paths and suggested fixes.

Do not make changes during review unless explicitly asked. If asked to fix issues, keep fixes narrow and report what changed.

## Stop Discipline

- When the requested task is complete, provide the final summary and stop.
- Do not perform post-completion exploration.
- Do not inspect extra files, read caches, call unrelated tools, prepare pushes, open PRs, or run extra verification unless explicitly asked.
- If more verification is needed, say exactly what remains and stop.

## Final Response Format

End coding tasks with:

- context read
- constraints found
- what changed
- checks run
- remaining risks or follow-ups

If checks were not run, say so and explain why.

If no files were changed, say so.

If blocked, explain the blocker, what was inspected, and the safest next step.
