---
description: Read-only map of the current repository purpose, boundaries, tooling, and checks
agent: context-scout
subtask: true
---

Load `context-discovery` and `managed-environment`.

Do not edit files.
Do not continue into planning or implementation.
Do not read secret values.

Build a compact workspace map for the current directory:

1. Inspect git state and current branch.
2. Find nearest repository instructions and README files.
3. Inspect only top-level build/tooling files such as `flake.nix`, `.envrc`,
   `Makefile`, `package.json`, `go.mod`, `*.sln`, `*.slnx`, `*.csproj`,
   CI workflows, and local task-runner docs.
4. Identify generated, artifact, deploy, secret, and runtime-state surfaces by
   path/name only unless local docs make them safe to read.

Report:

- `Repository`: name/root and apparent purpose
- `Boundaries`: what this repo owns and does not own
- `Tooling`: dev shell, task runner, package manager, CI, container/runtime notes
- `Sharp paths`: secrets, generated files, artifacts, deploy config, runtime state
- `Checks`: likely validation commands, with confidence and source
- `Unknowns`: only questions that affect safe execution

Stop after the map.
