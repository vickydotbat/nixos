---
name: workflow-preservation
description: Use when modifying shared infrastructure, dispatch, commands, startup, readiness, pipelines, adapters, serialization, permissions, migrations, background workers, or shared services. Ensures existing workflows still work after a change.
compatibility: opencode
---

# Workflow Preservation

Do not verify only the new path. If a change touches shared infrastructure, old workflows may break.

## Before Editing

Load and apply `context-discovery` first.

Identify existing workflows that use the touched code. Pay attention to:

- command dispatch
- chat/message/event handling
- startup and readiness
- plugin/module loading
- pipelines
- adapters and integration boundaries
- serialization/deserialization
- permissions and authorization
- database migrations and persistence
- background workers
- cache invalidation
- scheduled jobs

## Required Plan Item

For each important affected workflow, state:

- what workflow might be affected
- why it might be affected
- how it will be verified
- whether verification is automated or manual

## Review Checklist

Flag changes that:

- prove only the new feature path works
- alter shared dispatch without checking existing commands/events
- change lifecycle/readiness without checking startup and shutdown
- change adapters without checking existing adapter consumers
- update tests only around the new path
- remove old behavior without explicit approval

## Output

Report:

1. Workflows identified.
2. Workflows verified.
3. Workflows not verified and why.
4. Remaining manual checks.
