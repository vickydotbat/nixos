---
name: context-discovery
description: Mandatory context pass before non-trivial code changes. Use when starting implementation, reviewing a diff, touching architecture, subsystem behavior, public APIs, concurrency, data, deployment, tests, or unfamiliar code. Forces the agent to find and read relevant repository documentation before editing.
compatibility: opencode
---

# Context Discovery

Do not start implementation until the relevant repository context is understood.

This skill is mandatory before non-trivial edits, reviews, refactors, bug fixes, test changes, architecture changes, public behavior changes, or work in unfamiliar code.

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

## Required Report Before Editing

Before making changes, report:

1. Files and docs read.
2. Relevant constraints discovered.
3. Existing patterns that should be followed.
4. Canonical infrastructure or services that should be reused.
5. Workflows that may be affected.
6. Likely files to change.
7. Uncertainty or missing context.

Do not proceed if missing context could affect correctness, safety, architecture, data, concurrency, deployment, or public behavior.

## Failure Mode This Prevents

Weak agents often implement locally without noticing repository documentation, existing lifecycle/readiness flows, concurrency assumptions, or old workflows. This skill forces the agent to understand the system before changing it.
