---
name: artifact-boundary-discipline
description: Use when touching generated files, build artifacts, release pins, deployment manifests, CI publish gates, container image tags, binary assets, package outputs, host/runtime state, or source/deploy repository boundaries.
compatibility: opencode
---

# Artifact Boundary Discipline

Every file has a station in the mechanism: source, generated output, release
pin, deploy contract, runtime state, or binary artifact. Do not repair one by
quietly moving responsibility into another.

Use this skill for implementation or review near build outputs, release
manifests, generated files, CI workflows, deployment config, package images, or
large/binary assets. Load `context-discovery` first. Add
`managed-environment`, `dependency-discipline`, or `secret-authority-discipline`
only when the touched surface requires them.

## Classify The Surface

Before editing, classify each touched path:

- authored source: maintained directly by humans
- generated file: produced by a declared script, build, render, or codegen step
- release pin/snapshot: intentionally committed record of artifact identity
- build artifact: produced output, image layer, package, archive, binary, cache
- deploy authority: configuration that decides what runs in an environment
- runtime state: database, upload, log, cache, local workspace, mounted volume

If classification is unclear, read the nearest `AGENTS.md`, README, Makefile,
flake, workflow, or runbook before editing.

## Rules

- Do not hand-edit generated files when the generator is available and in
  scope. Change the source or generator, then regenerate narrowly.
- Do not commit build artifacts, large binaries, local workspaces, caches, logs,
  database state, or runtime outputs unless the repository explicitly defines
  them as source.
- Keep deploy authority in the repository or module that owns deployment. Source
  repositories may produce artifacts; deploy repositories pin and run them.
- Prefer immutable artifact identities such as content hashes, versioned
  releases, or git-SHA image tags. Do not introduce mutable production tags.
- CI publish/deploy workflows must fail closed. Do not turn missing artifacts,
  missing backups, unsigned releases, or deploy gates into warnings.
- Pull-request checks may build or validate artifacts, but publishing and
  production deployment should stay behind explicit release/manual gates unless
  the repository says otherwise.
- Treat lockfiles, release snapshots, generated Nix bridges, and vendored output
  as high-noise surfaces: touch them only when the task requires it.

## Review Red Flags

Flag:

- deployment config added to a source-only repository
- source-path builds in production deploy config where pinned artifacts are the
  contract
- generated output changed without the source/generator change that explains it
- binary, cache, workspace, local runtime, or large artifact files added to Git
- mutable image tags used for production
- CI workflows that publish or deploy on pull requests without an explicit local
  rule permitting it
- release or backup gates weakened from failure to warning

## Output

Report:

1. Classification of touched artifact/deploy surfaces.
2. Canonical generator, release, or deploy mechanism found.
3. Any generated or artifact files intentionally left untouched.
4. Verification run, or the exact generation/check command still needed.
