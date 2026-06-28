---
description: Read-only C# hygiene, async, test, and workflow preservation review
agent: csharp-reviewer
subtask: true
---

Load `context-discovery`, `code-hygiene`, `concurrency-async-safety`,
`testing-discipline`, `architecture-responsibility`, and
`workflow-preservation` only as needed by the C# diff.

Do not edit files.
Do not review unrelated languages or unrelated repository areas.

Review the current C# packet diff for:

- C# file/type layout and namespace/folder placement
- async/concurrency safety
- sync-over-async: `.Result`, `.Wait()`, `GetAwaiter().GetResult()`
- cancellation, lifecycle, readiness, and unobserved task exceptions
- test-only production APIs
- speculative safety code, locks, retries, fallbacks, or future-proofing
- stale responsibility names, folders, comments, or docs
- repeated magic literals that should become local named constants
- old workflow preservation

Report concrete findings first, ordered by severity, with file paths and
suggested fixes. If no issues are found, say that plainly and name any checks
or risks that remain unverified. Stop after the review.
