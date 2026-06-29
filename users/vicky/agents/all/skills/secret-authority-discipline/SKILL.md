---
name: secret-authority-discipline
description: Use when a task touches or may expose secrets, credentials, tokens, certificates, `.env` files, SOPS/age material, auth files, provider config, deploy keys, runtime secret paths, or secret templates. Keeps secret values unread, unprinted, and out of generated text.
compatibility: opencode
---

# Secret Authority Discipline

Secrets are authority, not ordinary configuration.

Use this skill when implementing, reviewing, debugging, documenting, or running
commands near secret material. Load `context-discovery` first for non-trivial
work. Also load `managed-environment` for setup/runtime changes and
`artifact-boundary-discipline` when secrets cross build, deploy, or release
surfaces.

## Classify First

Before acting, identify which class is involved:

- secret value: token, password, key, certificate, private auth file
- encrypted secret: `.sops`, `.age`, encrypted repository payload
- secret reference: option name, env var name, path, template key, service input
- example/template: placeholder format with no real credential
- runtime path: `/run/secrets`, `/run/agenix`, service-mounted secret file
- local machine state: `.env`, auth cache, SSH material, provider config

Only secret references and examples are normally safe to inspect or edit.

## Rules

- Do not print, cat, echo, copy, summarize, commit, or paste real secret values.
- Do not read secret contents unless the user explicitly asks and the task
  cannot be done through metadata, path checks, schema checks, or templates.
- Do not put secret values in generated files, Nix strings, logs, docs,
  examples, command output, test fixtures, or model context.
- Prefer checking existence, ownership, mode, schema, variable names, and
  consumer wiring over opening the value.
- Keep secret examples obviously fake and low-entropy.
- If a command may reveal a secret, change the command to inspect metadata or
  stop and ask.
- Redact accidental secret-looking output before reporting it.

## Review Red Flags

Flag:

- real-looking values in docs, examples, tests, logs, or generated output
- `.env`, auth, SSH, token, provider, or secret-manager files in broad diffs
- SOPS/age files changed without a matching secret-management task
- service config that moves secrets into image builds, Nix store paths, CLI
  arguments, environment dumps, or world-readable files
- scripts that echo env, run with tracing around secrets, or upload secret files

## Output

Report:

1. Secret classes encountered.
2. What was inspected without exposing values.
3. Any value-bearing files intentionally left unread.
4. Remaining operator action, if a real secret must be created or rotated.
