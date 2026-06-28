---
description: Review current diff against repository context without editing
---

Load `pr-readiness`.
Load `context-discovery`.
Load other relevant skills based on the diff.

Do not edit files.

Review the current diff for correctness and PR readiness.

Report concrete findings with file paths, severity, and suggested fixes.

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
