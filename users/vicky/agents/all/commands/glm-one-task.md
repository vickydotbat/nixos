---
description: Run GLM as a bounded worker for exactly one named task
agent: glm-worker
---

Use the `glm-worker` agent only.

Implement exactly one named task from the user's prompt.

Rules:

- Do not dispatch subagents.
- Do not commit, push, reset, clean, or rewrite Git history.
- Do not read secrets, credentials, tokens, `.sops`, auth files, `/run/secrets`,
  `/run/agenix`, SSH material, or provider configuration containing keys.
- Do not broaden scope beyond the named task.
- Use at most four tool steps.
- If tests fail, report the failure and stop.
- After the task is complete, summarize the files changed, checks run, and
  remaining risk, then stop.
