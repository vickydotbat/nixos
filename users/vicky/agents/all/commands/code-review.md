---
description: Review code changes for hygiene, responsibility, async safety, tests, and scope control
---

Load `context-discovery`, then choose the smallest relevant set of review skills:

- `context-discovery`
- `code-hygiene`
- `concurrency-async-safety`
- `architecture-responsibility`
- `testing-discipline`
- `workflow-preservation`

Do not edit files.

Review code changes for:

- fit with repository-local style and conventions
- honest ownership, names, folders, and module boundaries
- stale names, comments, docs, or paths after responsibility changes
- unsafe blocking, lifecycle, readiness, cancellation, or shared-state assumptions
- local lifecycle/readiness/retry/cache fallbacks beside canonical services
- production APIs added only for tests
- speculative locks/configuration/retries/fallbacks/future-proofing
- duplicated canonical values
- broad formatting or generated-file noise
- repeated magic literals that should be constants
- old workflows affected but not verified

Report concrete findings with file paths and suggested fixes. Keep context
summary compact; do not reproduce docs or large diffs.
