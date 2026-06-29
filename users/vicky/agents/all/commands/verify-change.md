---
description: Choose and run the narrowest useful verification for the current diff
---

Load `git-safety` and `managed-environment`.
Load `artifact-boundary-discipline` or `secret-authority-discipline` only if
the diff touches those surfaces.

Do not edit files.
Do not commit, push, deploy, start long-running services, reset databases, or
run destructive cleanup.
Do not read secret values.

Verify the current change:

1. Inspect `git status --short`, `git branch --show-current`,
   `git diff --stat`, and `git diff --name-only`.
2. Read the nearest repository instructions and only the build/test docs needed
   to choose checks.
3. Prefer existing repo commands: Make targets, package scripts, flakes,
   dev-shell commands, CI contract scripts, language test commands.
4. Start with the narrowest check that covers the changed files.
5. Run broader checks only when the narrow check passes and local docs make the
   broader check clearly appropriate.

Avoid production/deploy actions unless the user explicitly requested that
class of verification. For NixOS rebuilds, remote deploys, disks, LUKS,
impermanence, and destructive commands, ask for execution context first.

Report:

- `Diff`: branch and changed-file summary
- `Chosen checks`: commands selected and why
- `Results`: pass/fail with concise failure detail
- `Not run`: relevant checks skipped and why
- `Risk`: remaining unverified behavior
