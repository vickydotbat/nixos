---
description: Read-only review of generated files, artifacts, release pins, deploy gates, and secrets
agent: diff-reviewer
subtask: true
---

Load `context-discovery`, `artifact-boundary-discipline`, and
`secret-authority-discipline`.

Do not edit files.
Do not read secret values.
Do not broaden into a general PR review unless the user asks.

Review the current diff for artifact and authority boundaries:

- source repository vs deploy repository responsibility
- generated files changed without source/generator explanation
- binary, cache, workspace, local runtime, or large artifact files added to Git
- release pins, lock snapshots, generated bridges, and vendored output changed
  without an intentional release/update task
- mutable production image tags
- source-path builds in production deploy config
- CI publish/deploy gates on pull requests
- fail-closed checks weakened into warnings
- secret values, auth files, `.env`, `.sops`, provider config, SSH material, or
  runtime secret paths exposed or mishandled

Report concrete findings first, ordered by severity, with file paths and
suggested fixes. If no issues are found, say that plainly and name any checks
or risks that remain unverified.
