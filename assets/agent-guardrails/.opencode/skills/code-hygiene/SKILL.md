---
name: code-hygiene
description: Use for implementation or review in any language. Enforces idiomatic local style, truthful names and placement, focused APIs, behavior-preserving tests, async/lifecycle caution, and low-noise edits.
compatibility: opencode
---

# Code Hygiene

Apply this skill when editing or reviewing code in any repository.

Load and apply `context-discovery` first for non-trivial work. Also load `concurrency-async-safety` when touching async, lifecycle, workers, plugins, events, queues, IO, or shared state.

## Local Style

Follow the repository's existing language conventions before importing outside preferences.

Check nearby files for:

- file and type layout
- naming and module boundaries
- error handling style
- dependency injection or construction patterns
- formatting and linting expectations
- test structure and fixture style

When the repository has an explicit convention, follow it. When it does not, prefer simple, idiomatic code for the language and keep new public surface small.

## Truthful Placement

Keep folders truthful:

- Domain data and rules belong under the feature's domain area.
- File-system, network, database, framework, and third-party boundaries belong under adapter or integration areas when the repository uses those boundaries.
- Pipeline stages, commands, handlers, plugins, jobs, and services belong with the subsystem that owns their lifecycle.
- A type or module converted to a new responsibility should move or be renamed when leaving it in place would mislead the next maintainer.

Naming must follow responsibility:

- If a name no longer describes current behavior, update it in the same change when doing so is within scope.
- Do not leave stale names, folders, or comments after refactors.

## API Shape

Do not add public API surface only to make an implementation or test easier.

Avoid test-only:

- constructors
- methods
- flags
- configuration options
- visibility changes
- fake public modes

Prefer existing public behavior, existing test infrastructure, or extraction of a real pure rule that improves production design.

## Async and Lifecycle

Respect the existing execution model.

For async, worker, server, plugin, event, request, or shared-state paths, load `concurrency-async-safety` and preserve existing cancellation, readiness, startup, shutdown, ownership, and error-observation patterns.

## Anti-Speculation

Avoid code for hypothetical future requirements.

Do not add:

- abstractions without a current caller or clear simplification
- duplicate canonical IDs or settings
- fallback branches without a current failure mode
- compatibility layers without a verified consumer
- locks, retries, caches, or registries without evidence they are needed

Promote repeated magic literals to a named constant when repetition is local and the name improves clarity.

## Review Checklist

Check for:

- style that conflicts with nearby code
- stale names, folders, comments, or docs
- responsibility or ownership drift
- test-only production API additions
- speculative abstractions, settings, retries, locks, caches, or fallbacks
- duplicated canonical values
- broad formatting churn
- dead code or needless indirection
- repeated magic literals that should be constants
