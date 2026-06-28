---
description: Prepare a branch for PR without broadening scope
---

Load `pr-readiness` first.

Do not broaden scope.

Inspect:

```bash
git status --short
git branch --show-current
git diff --stat
git diff --name-only
```

Then perform a PR-readiness pass against repository context.

Check for:

- scope creep
- unrelated files
- stale names/folders after responsibility changes
- missing docs/tests
- brittle tests
- unsafe async/concurrency
- local mechanisms duplicating canonical infrastructure
- speculative safety code
- production API added only for tests
- old workflows not verified
- noisy generated/lockfile changes

If making fixes, keep them narrow.

Report:

- context read
- issues found
- fixes made
- checks run
- remaining risks
