---
name: concurrency-async-safety
description: Use when touching async, threading, workers, tasks, queues, locks, cancellation, lifecycle, readiness, server code, shared state, plugins, background jobs, IO, event handlers, or code that may run concurrently. Blocks sync-over-async patterns such as GetAwaiter().GetResult(), .Result, and Wait().
compatibility: opencode
---

# Concurrency and Async Safety

Concurrency, async execution, scheduling, lifecycle management, readiness, cancellation, shutdown, and shared mutable state are high-risk.

If unsure whether the code is single-threaded, assume it may be concurrent until proven otherwise.

## Before Editing

Load and apply `context-discovery` first.

Read:

- relevant architecture or subsystem docs
- nearby implementation code
- existing tests
- lifecycle/readiness/shutdown/cancellation paths
- existing async/threading patterns in the same subsystem

Identify:

- who owns the task/thread/job
- how cancellation works
- how exceptions are observed
- what state is shared
- what synchronization or immutability already exists
- whether ordering matters
- whether the caller is async, threaded, event-driven, request-based, worker-based, or plugin-based
- whether readiness/startup/shutdown infrastructure already exists

## Forbidden Unless Explicitly Justified by Existing Architecture

Do not introduce sync-over-async or blocking waits in concurrent, async, or server code.

Avoid:

- `.Result`
- `.Wait()`
- `GetAwaiter().GetResult()`
- blocking an event loop
- blocking request, worker, plugin, or server paths
- blocking sleeps instead of awaiting or signaling
- fire-and-forget tasks without ownership, logging, cancellation, and exception handling
- shared mutable state without synchronization or immutability
- new global/static mutable state in request, worker, plugin, or server code
- swallowed task/thread exceptions
- ignored cancellation tokens
- timeout-free waits
- local readiness/migration/lifecycle fallbacks when canonical infrastructure exists

Equivalent patterns in other languages are also risky.

## Required Checks

When touching concurrent code, verify:

- async boundaries are preserved
- cancellation and shutdown behavior are respected
- readiness/lifecycle behavior follows existing infrastructure
- exceptions are observed and handled
- shared state is protected or avoided
- ordering assumptions are explicit
- tests do not rely on timing unless unavoidable

## Review Red Flags

Flag these during review:

- sync-over-async
- hidden blocking calls in request/worker/event/plugin paths
- tasks started but never awaited, tracked, cancelled, or logged
- locks around async calls
- mutable static/global caches
- timing-based tests
- missing cancellation propagation
- swallowed exceptions
- changes that assume single-threaded execution without evidence
- local readiness workarounds beside canonical readiness services
