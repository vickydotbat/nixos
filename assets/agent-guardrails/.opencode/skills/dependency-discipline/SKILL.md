---
name: dependency-discipline
description: Use when adding, removing, updating, reviewing, or troubleshooting dependencies, packages, lockfiles, build tools, dev tools, flakes, containers, or package managers. Prevents casual dependency churn and broad upgrades.
compatibility: opencode
---

# Dependency Discipline

Dependencies are part of architecture and maintenance cost.

Do not add or upgrade dependencies casually.

## Before Changing Dependencies

Load and apply `context-discovery` first.

Identify:

- existing dependency manager and lockfile
- existing standard-library or project-local alternatives
- whether the dependency is runtime, build-time, test-only, or dev-only
- whether the change affects deployment, CI, packaging, or managed environments
- whether the repo has policy docs for dependency updates

## Rules

- Prefer standard library and existing dependencies.
- Ask before adding runtime dependencies.
- For dev-only dependencies, explain why existing tooling is insufficient.
- Do not update lockfiles unless the task requires it or the package manager does so as part of the requested change.
- Do not perform broad package upgrades unless explicitly asked.
- Do not change dependency managers, build systems, or environment tooling without approval.
- Do not add packages to work around missing local tooling before checking the repo's managed environment.

## Output

When dependency changes are necessary, report:

1. Why the dependency change is needed.
2. What alternatives were checked.
3. Whether it is runtime, build, test, or dev-only.
4. What lockfiles or generated files changed.
5. What checks were run.
