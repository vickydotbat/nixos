---
name: nixos-environment
description: Use when working on NixOS, flakes, dev shells, package availability, scripts, services, system modules, Home Manager, containers, or environment/setup issues. Avoids generic Linux/FHS assumptions and ad hoc dependency installation.
compatibility: opencode
---

# NixOS and Managed Environment Discipline

Do not assume a generic Linux or FHS environment.

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
- Ask before changing system-level or Home Manager configuration.
- Do not start long-running services from activation scripts.
- Do not add ad hoc install instructions that bypass the repository's environment model.

## When Adding Tooling

Before adding environment tooling, explain:

1. What command failed or dependency was missing.
2. What existing repo tooling was checked.
3. Why the existing tooling is insufficient.
4. The smallest scoped environment change that solves the problem.

Prefer project-local, reversible, reviewable changes.
