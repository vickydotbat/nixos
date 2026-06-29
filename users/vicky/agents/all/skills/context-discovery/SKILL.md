---
name: context-discovery
description: Right-sized context pass before non-trivial code changes. Use when starting implementation, reviewing a diff, touching architecture, subsystem behavior, public APIs, concurrency, data, deployment, tests, or unfamiliar code. Forces the agent to find and read relevant repository documentation before editing.
compatibility: opencode
---

# Context Discovery

Do not start non-trivial implementation until the relevant repository context is understood.

Use this skill before non-trivial edits, reviews, refactors, bug fixes, test changes, architecture changes, public behavior changes, or work in unfamiliar code.

Use enough context to avoid local, misleading edits. Do not load unrelated docs
or paste long excerpts into the conversation.

## Context Sources

Before editing, identify and read relevant sources:

- repository instructions: `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, `.github/copilot-instructions.md`
- `README`, `CONTRIBUTING`, setup docs, developer docs
- `docs/`, `documentation/`, `architecture/`, `design/`, `adr/`, `notes/`, wiki exports, subsystem docs
- package/build metadata
- CI workflows and test configuration
- nearby implementation files
- existing tests for the target behavior
- recent related commits when useful

Search for the task's terms and nearby architectural terms.

Depending on the task, search for terms such as:

- feature, module, class, function, command, setting, interface, or config names
- public API names
- error messages
- `thread`, `async`, `await`, `lock`, `mutex`, `queue`, `worker`, `parallel`, `task`, `scheduler`, `cancellation`, `timeout`, `race`, `deadlock`, `lifecycle`, `startup`, `shutdown`, `readiness`
- `transaction`, `migration`, `consistency`, `idempotent`, `retry`, `cache`, `persistence`
- `auth`, `permission`, `secret`, `token`, `credential`, `role`, `policy`

## Awareness Packet Before Editing

Before making non-trivial changes, report a compact packet:

1. `Context`: files, docs, tests, and configuration read.
2. `Constraints`: local rules, public contracts, and safety boundaries found.
3. `Canonical`: existing mechanisms, services, helpers, or patterns to reuse.
4. `Impact`: old workflows or shared paths that may be affected.
5. `Plan`: minimal files and steps likely needed.
6. `Unknowns`: missing context, if it changes risk or scope.

Keep the packet short. Name evidence; do not reproduce it.

Do not proceed into an uncertain high-risk surface if missing context could affect correctness, safety, architecture, data, concurrency, deployment, or public behavior. Narrow the change or ask.

## Failure Mode This Prevents

Weak agents often implement locally without noticing repository documentation, existing lifecycle/readiness flows, concurrency assumptions, or old workflows. This skill gives the agent peripheral vision before changing the system.
