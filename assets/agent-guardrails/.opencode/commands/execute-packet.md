---
description: Execute exactly one approved implementation packet and stop
---

Use only the approved packet. Do not revisit the whole plan.

Before editing, load `git-safety` and only the smallest relevant implementation
skills:

- `context-discovery`
- `architecture-responsibility`
- `workflow-preservation`
- `concurrency-async-safety`
- `testing-discipline`
- `code-hygiene`
- `dependency-discipline`
- `managed-environment`

Rules:

- Implement exactly one packet.
- Do not continue from packet 1 into packet 2 unless this command explicitly
  asks for packet 2.
- Do not load unrelated skills, tools, docs, or repository areas.
- Use only the files relevant to the packet, except for a specific blocker.
- Do not broaden scope.
- Do not touch unrelated files.
- Do not add speculative abstractions, locks, fallbacks, retries, dependencies,
  services, modules, or config.
- Do not add production API surface solely for tests.
- Preserve responsibility boundaries and truthful names/folders.
- Verify affected old workflows when shared infrastructure changed.

Hard stop conditions:

- If the packet grows beyond the approved scope, split it and stop.
- If context is too large, stop and request a smaller packet.
- If uncertainty blocks implementation, list it as an open question and stop.
- If output becomes incoherent, repetitive, corrupted, unrelated, or
  token-soup-like, stop immediately and do not edit further.

On meltdown or suspected context collapse, report only:

- last successful action
- files touched
- current `git diff --stat`
- checks not run
- safest next step

After changes:

1. Inspect final diff.
2. Run the narrowest relevant checks.
3. Report context read, what changed, checks run, and remaining risks.
4. Stop after the packet summary.
