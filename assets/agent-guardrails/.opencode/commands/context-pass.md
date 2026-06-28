---
description: Identify and read relevant repository context before implementation
---

Load the `context-discovery` skill.

Do not edit files.

Perform a right-sized context pass for the requested task:

1. Inspect git state.
2. Identify relevant repository instructions, docs, architecture notes, tests, and nearby code.
3. Read the relevant files.
4. Search for task terms and relevant architecture/concurrency/data/security terms.
5. Report a compact awareness packet:
   - `Context`: docs/files/tests/config read
   - `Constraints`: local rules and safety boundaries found
   - `Canonical`: mechanisms or patterns to reuse
   - `Impact`: existing workflows that may be affected
   - `Plan`: likely files and minimal steps
   - `Unknowns`: missing context or questions

Stop after the report.
