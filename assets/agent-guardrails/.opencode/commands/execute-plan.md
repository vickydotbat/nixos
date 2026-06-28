---
description: Execute an approved plan narrowly and report verification
---

Use only the approved plan.

Before editing, load `git-safety` and any relevant implementation skills:

- `context-discovery`
- `architecture-responsibility`
- `workflow-preservation`
- `concurrency-async-safety`
- `testing-discipline`
- `code-hygiene`
- `dependency-discipline`
- `managed-environment`

Rules:

- Do not broaden scope.
- Do not touch unrelated files.
- Do not add speculative abstractions, locks, fallbacks, or config.
- Do not add production API surface solely for tests.
- Preserve responsibility boundaries and truthful names/folders.
- Verify affected old workflows when shared infrastructure changed.

After changes:

1. Inspect final diff.
2. Run the most relevant checks.
3. Report context read, constraints found, what changed, checks run, and remaining risks.
