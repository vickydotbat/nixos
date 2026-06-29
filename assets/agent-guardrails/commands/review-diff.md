---
description: Review current diff against repository context without editing
---

Load `pr-readiness`, then any other skills needed by the diff. Do not load
every skill by default.

Do not edit files.

Review the current diff for correctness and PR readiness.

Report concrete findings with file paths, severity, and suggested fixes.
Keep context summary compact.

Focus especially on:

- violations of repository docs or architecture
- responsibility/name/folder drift
- unsafe async, lifecycle, readiness, or shared-state assumptions
- old workflows affected but not verified
- brittle tests or test-shaped production code
- speculative abstractions, locks, settings, or fallbacks
- public behavior/API changes
- security/privacy risks

Stop after the review.
