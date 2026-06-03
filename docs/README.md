# Docs

This directory holds plans and notes for repository maintenance.

These files are not the system configuration itself. They are the repair ledger: what was intended, what order made sense, and which failure modes were visible before the work began.

## What It Controls

- implementation plans under `superpowers/plans/`
- agent-facing task notes that should remain executable
- hardening compatibility notes such as `hardening-compatibility.md`
- package inventory review notes such as `package-inventory.md`
- historical context for structural repairs

## Writing Plan Notes

Keep plans concrete:

- name the purpose
- list the files that should change
- preserve checkbox syntax when a worker will execute the plan
- state validation commands
- call out failure modes before the work begins

## Failure Modes

- A plan that omits validation invites a clean-looking breakage.
- A plan that hides uncertainty turns future maintenance into archaeology.
- A plan that drifts from the current tree should be updated or clearly marked historical.

## Maintenance Reminders

When the repository structure changes, check old plans for stale option namespaces, file names, and import paths. Documentation does not need to be immortal, but it should not quietly lie.
