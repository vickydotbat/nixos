---
description: Review the current packet diff without editing
agent: diff-reviewer
subtask: true
---

Load `pr-readiness`, then only the other skills needed by the packet diff.

Do not edit files.
Do not review unrelated repository areas.
Do not broaden scope beyond the current packet.

Review only the current diff for the packet. Check against:

- repository `AGENTS.md`
- relevant guardrail skills
- nearby architecture, tests, and docs
- old workflows named by the packet plan

Focus especially on:

- instruction or architecture violations
- stale responsibility names, stale folders, or stale comments
- unsafe async, lifecycle, readiness, or shared-state assumptions
- old workflows affected but not verified
- brittle tests or test-shaped production code
- speculative abstractions, locks, settings, retries, or fallbacks
- public behavior/API changes
- security/privacy risks

Report concrete findings with file paths, severity, and suggested fixes.
Keep context summary compact. Stop after the review.
