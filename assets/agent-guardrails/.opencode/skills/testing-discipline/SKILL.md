---
name: testing-discipline
description: Use when adding, editing, deleting, or reviewing tests. Enforces behavior-focused tests and prevents brittle assertions, test-only production APIs, mutable dictionary assertions, wording snapshots, incidental ordering, timing-based concurrency tests, or coverage-only tests.
compatibility: opencode
---

# Testing Discipline

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
- private helper behavior unless the helper is the public unit under test
- exact wording that may legitimately change
- incidental ordering
- variable names
- harmless constants
- mutable configuration values
- generated text
- broad snapshots that are not the feature under test
- dictionary/configuration values unless those exact values are intended public behavior

## Production Shape Rule

Do not add production API surface only to make a test easier.

Avoid test-only:

- constructors
- methods
- switches
- visibility changes
- dependency injection branches
- configuration options
- fake public modes

If behavior is hard to test because it is engine-bound or infrastructure-bound, prefer:

- extracting a real pure rule that improves production design
- testing through existing public behavior
- using existing seams/fakes/test infrastructure
- accepting manual verification when automated testing would damage production design

## When Fixing Tests

Do not weaken tests just to make them pass.

If removing or relaxing an assertion, explain why it was:

- brittle
- incorrect
- redundant
- no longer applicable
- testing implementation instead of behavior

## Regression Tests

For bug fixes, add focused regression coverage when practical.

A good regression test should fail before the fix and pass after the fix.

## Snapshot and Golden Output Rules

Avoid snapshots/golden outputs unless the exact output is a stable user-facing contract.

If snapshots are necessary, keep them small and focused.

## Concurrency Tests

Avoid tests that pass only because of timing, sleeps, or incidental scheduler behavior.

Prefer explicit synchronization, deterministic fakes, controlled clocks, cancellation tokens, bounded timeouts, and observable outcomes.
