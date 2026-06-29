---
name: managed-environment
description: Use when commands, dependencies, tool availability, package managers, dev shells, containers, CI, Nix flakes, Home Manager, or setup scripts matter. Avoids generic machine assumptions and ad hoc installation.
compatibility: opencode
---

# Managed Environment Discipline

Do not assume a generic machine, globally installed tools, or a particular filesystem layout.

Prefer repository-provided tooling and managed environments.

## Before Running Commands

Inspect for:

- `flake.nix`
- `shell.nix`
- `.envrc`
- `devenv.nix`
- `default.nix`
- devcontainer files
- Makefile or task runner config
- package manager metadata
- CI workflows
- documented setup commands

## Rules

- Do not assume globally installed tools are available.
- Prefer existing dev shells, flakes, containers, or task runners.
- If dependencies are missing, prefer entering an existing managed environment.
- Do not add a new flake, dev shell, package, service, module, or container unless necessary.
- Ask before changing system-level, user-profile, deployment, or persistent environment configuration unless the task explicitly asks for it.
- Do not start long-running services from activation scripts.
- Do not add ad hoc install instructions that bypass the repository's environment model.

## When Adding Tooling

Before adding environment tooling, explain:

1. What command failed or dependency was missing.
2. What existing repo tooling was checked.
3. Why the existing tooling is insufficient.
4. The smallest scoped environment change that solves the problem.

Prefer project-local, reversible, reviewable changes.
