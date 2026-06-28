---
description: Identify and read relevant repository context before implementation
---

Load the `context-discovery` skill.

Do not edit files.

Perform a context pass for the requested task:

1. Inspect git state.
2. Identify relevant repository instructions, docs, architecture notes, tests, and nearby code.
3. Read the relevant files.
4. Search for task terms and relevant architecture/concurrency/data/security terms.
5. Report:
   - docs/files read
   - constraints found
   - canonical mechanisms to reuse
   - existing workflows that may be affected
   - likely files to change
   - missing context or questions

Stop after the report.
