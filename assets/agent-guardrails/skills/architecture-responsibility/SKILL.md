---
name: architecture-responsibility
description: Use when adding, moving, renaming, refactoring, or reviewing services, interfaces, domain objects, adapters, pipeline stages, handlers, modules, folders, or responsibilities. Enforces truthful names, folders, ownership boundaries, and reuse of canonical infrastructure.
compatibility: opencode
---

# Architecture and Responsibility Discipline

Code location and names must tell the truth about current responsibility.

Do not make code compile while leaving architecture misleading.

## Before Editing

Load and apply `context-discovery` first.

Identify:

- which feature/subsystem owns the concept
- whether the type is domain, adapter, integration, pipeline, service, command, handler, or infrastructure
- existing neighboring patterns
- existing interfaces and service boundaries
- any docs that define ownership, lifecycle, or folder layout

## Placement Rules

- Domain data and rules belong under the feature's domain area.
- Engine, framework, file-system, network, and third-party boundaries belong under adapter or integration areas.
- Pipeline stages belong inside the pipeline feature folder that owns the pipeline.
- Services belong where their current responsibility is true.
- If a service stops being responsible for the thing named in its class or folder, rename or move it in the same change.
- Do not leave converted code in an old folder just because that is where it started.

## Existing Infrastructure Rule

Before adding a new local mechanism, look for an existing service-level or framework-level one.

Search before adding:

- readiness checks
- lifecycle hooks
- startup/shutdown gates
- retries
- caches
- locks
- queues
- schedulers
- registries
- fallback paths
- canonical ID/config sources

If existing infrastructure exists, reuse it unless you can explain why it is insufficient.

## Red Flags

Flag and fix, or ask before proceeding, when you see:

- stale class names after a responsibility change
- services pretending to be pipeline stages or vice versa
- domain records living beside adapters or callers
- adapter code mixed into domain rules
- local readiness/migration fallbacks beside canonical readiness infrastructure
- duplicated canonical IDs in settings
- speculative safety systems without a current failure mode
- future-proof abstractions without current users
