---
name: csharp-hygiene
description: Use for C#/.NET code changes or reviews. Enforces file/type layout, one public type per file, interface file placement, honest folders/names, async/server safety, no test-only production APIs, no speculative safety code, and consts for repeated literals.
compatibility: opencode
---

# C# and .NET Hygiene

Apply this skill when editing or reviewing C#/.NET code.

Load and apply `context-discovery` first. Also load `concurrency-async-safety` when touching async, server paths, lifecycle, workers, plugins, events, queues, or shared state.

## File and Type Layout

Use one public top-level type per file.

Rules:

- `IFooService` belongs in `IFooService.cs`.
- `FooOptions` belongs in `FooOptions.cs`.
- `FooResult` belongs in `FooResult.cs`.
- `FooService` belongs in `FooService.cs`.
- Interfaces always get their own file named after the interface.
- Public records, classes, enums, and structs get their own files.
- Do not put public interfaces, records, classes, enums, or structs at the bottom of a service file.

Small helper type exception:

- If a helper type is used by exactly one class, make it private/nested and put it at the bottom of that class.
- If another file needs the helper type, it is no longer a private helper and must move to its own file.

## Honest Placement

Keep folders truthful:

- Domain data and rules belong under the feature's domain area.
- Engine, Anvil, NWScript, file-system, network, database, and third-party boundaries belong under adapter or integration areas.
- Pipeline stages belong inside the pipeline feature folder that owns the pipeline.
- A class converted from service to pipeline stage should move with the pipeline instead of staying in the old service folder.

Naming must follow responsibility:

- If a service stops being responsible for the thing named in its class or folder, rename or move it in the same change.
- Do not leave stale names after refactors.

## Async and Server Paths

Never use sync-over-async in server paths:

- no `.Result`
- no `.Wait()`
- no `.GetAwaiter().GetResult()`

Prefer async all the way through existing async call chains.

Respect:

- cancellation tokens
- readiness services
- startup/shutdown flows
- dependency injection lifetimes
- existing lifecycle infrastructure

Do not build local migration/readiness/lifecycle fallbacks when an existing service-level mechanism exists.

## Testing and Production Shape

Do not add production methods, constructors, switches, or visibility solely for tests.

Tests should use real public behavior.

If behavior is too engine-bound to test directly:

- extract a real pure rule if that improves production design
- test through existing public seams
- use existing test infrastructure
- accept manual verification for that path when appropriate

Do not damage production API shape for test convenience.

## Anti-Speculation

Avoid speculative safety code.

Do not add:

- locks around immutable startup data
- duplicate canonical IDs in settings
- fallback settings for values with one authoritative source
- future-proofing branches without current requirements
- abstractions with no current caller or simplification

Promote repeated magic literals to a named `const` near the top of the class when repetition is local and the constant improves clarity.

## Review Checklist

Check for:

- multiple public top-level types in one file
- public interfaces/records/enums/classes hiding below service code
- helper types that should be private nested types
- helper types that escaped one class but did not move to their own file
- stale service names or folders
- domain/adapter/pipeline placement mistakes
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()`
- test-only production API additions
- local readiness/lifecycle fallbacks
- speculative locks/configuration/future-proofing
- repeated magic literals that should be constants
