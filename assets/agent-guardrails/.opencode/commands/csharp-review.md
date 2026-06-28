---
description: Review C#/.NET changes for hygiene, async safety, layout, and test damage
---

Load these skills:

- `context-discovery`
- `csharp-hygiene`
- `concurrency-async-safety`
- `architecture-responsibility`
- `testing-discipline`
- `workflow-preservation`

Do not edit files.

Review C#/.NET changes for:

- one public top-level type per file
- interfaces and public records/classes/enums/structs in their own files
- helper types private/nested only when used by one class
- honest domain/adapter/pipeline placement
- stale service names/folders after responsibility changes
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()`
- local readiness/lifecycle fallbacks beside canonical services
- production APIs added only for tests
- speculative locks/config/future-proofing
- repeated magic literals that should be constants
- old workflows affected but not verified

Report concrete findings with file paths and suggested fixes.
