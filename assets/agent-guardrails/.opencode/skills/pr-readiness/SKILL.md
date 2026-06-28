---
name: pr-readiness
description: Use when preparing a branch for PR, reviewing a diff, cleaning up a branch, or checking merge readiness. Requires context discovery before review and checks for scope creep, responsibility drift, stale folders/names, brittle tests, docs drift, unsafe concurrency, test-only APIs, speculative safety code, and noisy diffs.
compatibility: opencode
---

# PR Readiness

A PR-readiness pass is a review and cleanup workflow, not an excuse to broaden scope.

Before reviewing, load and apply `context-discovery`.

Load only the other skills relevant to the diff:

- `architecture-responsibility`
- `workflow-preservation`
- `concurrency-async-safety`
- `testing-discipline`
- `code-hygiene`
- `git-safety`

## Inspect First

Start with:

```bash
git status --short
git branch --show-current
git diff --stat
git diff --name-only
```

When useful:

```bash
git log --oneline -5
git diff
```

## Review Against Context

Read relevant repository docs, architecture notes, tests, and nearby code before judging the diff.

Check whether the change conflicts with:

- project documentation
- architecture rules
- ownership/folder conventions
- concurrency/threading/lifecycle assumptions
- public API contracts
- test strategy
- deployment assumptions
- security/privacy expectations

## Check For

- scope creep
- unrelated files
- stale names or folders after responsibility changes
- public APIs, types, modules, or files placed in the wrong owner
- local mechanisms that duplicate canonical infrastructure
- speculative safety code, locks, configuration, retries, or future-proofing
- unsafe async/concurrency changes
- sync-over-async
- old workflows not verified after shared infrastructure changed
- production API surface added only for tests
- brittle tests
- missing tests
- missing docs
- inconsistent naming or style
- dead code
- needless abstractions
- duplicated logic
- error handling gaps
- data migration or compatibility risks
- security or privacy risks
- dependency or lockfile noise
- generated file noise
- CI failures or missing verification

## Output

Report:

1. Compact awareness packet.
2. What changed.
3. Concrete issues with file paths.
4. Suggested fixes.
5. Checks run or checks still needed.
6. Remaining risks.

Do not edit during review unless explicitly asked.

If asked to fix issues, keep changes narrow and report exactly what changed.
