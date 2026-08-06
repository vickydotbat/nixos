# Global agent rules

Short, always-on rules. The full reasoning is in the `engineering-policy` skill
— load it with `/skill:engineering-policy` for non-trivial or unclear work.

## Before you edit — every time

1. **Read the rules for THIS path first.** Read the nearest `AGENTS.md` (the
   engine auto-loads the chain from cwd up). If a project skill matches your task
   (e.g. threading, NUI, hooks, conventions), open its `SKILL.md` and follow it
   — do not work from memory. Weak recall is the top cause of broken conventions.
2. **State a one-line plan** for anything beyond a trivial edit: what you'll
   change, which files, how you'll check it. Multi-file or refactor work gets a
   short written plan first (see `engineering-policy`).
3. **Match the surrounding code.** Follow the project's existing naming, file
   layout, and idioms. The nearest `AGENTS.md` wins over your defaults.

Stay on the task. Don't drift into refactors, renames, dependency bumps, or
"cleanups" that weren't asked for.

## Workflow — wargames

One flow, scaled to the task. No SDD/spec bureaucracy; the artifacts are the
plan note, the diff, and the verdict.

1. **Scout** — trivial edits: read the touched code yourself. Anything
   multi-file or unfamiliar: dispatch the `scout` subagent (read-only) for a
   brief of touch points, flow, reuse candidates, tests, and risks.
2. **Plan** — one-line plan for small work; for larger work use
   `/skill:brainstorming` / `/skill:writing-plans` and keep the plan in a short
   note the user can veto. Debugging → `/skill:systematic-debugging`.
3. **Build** — you implement, smallest working diff, tests alongside behavior
   changes.
4. **Verify adversarially** — never grade your own homework:
   - normal change: dispatch `verifier` on the diff (it tries to refute "done");
   - pre-PR or risky change: run the `4r-review` chain — four blind review
     lenses, `verifier` merges and confirms;
   - confirmed findings → `fixer` (surgical, root-cause), then re-verify.

Subagents get a scoped brief (what changed, where, how to check) — not the
whole conversation. Reviewers stay blind to each other; only the verifier
reads all reports.

## Safety — hard rules

- **Git:** Don't commit unless asked. Never commit to `main`/`master`. Never
  force-push, `reset --hard`, `git clean`, delete branches, or rewrite history
  unless explicitly asked. (Enforced at the tool boundary by `git-safety-gate`.)
- **AI attribution:** If a commit trailer identifies this agent, use
  `Co-Authored-By: Pi Agent <pi-agent@local.invalid>`. Do not copy model- or
  vendor-specific attribution from specs or examples.
- **Stay on the current branch.** Preserve unrelated user changes; mention them.
- **Secrets:** never read, print, move, or commit `.env`, `.sops`, keys, tokens,
  or credentials. If a command might expose secrets, don't run it.
- **Scope:** ask before anything touching architecture, data, migrations,
  deployment, or compatibility. Prefer the simplest thing that works.

## Verify before you claim done

- For non-trivial changes, run at least one relevant check or test.
- If you couldn't run it, say so plainly — name what you skipped and why.
- Never report success you didn't verify. Don't hide failures or partial work.
- Test behavior, not incidental details (wording, ordering, snapshots).

## Restraint

Ponytail mode is active for output and implementation restraint: smallest
working diff, stdlib/native before dependencies, no speculative abstractions.

## Environment

This machine runs NixOS — see the appended NixOS rules. Prefer repo-native Nix
entry points (`flake.nix`, `nix develop`, `just`, documented commands). No
`sudo`, no ad-hoc global installs.

---

Full policy, Context Receipt, locality, testing, docs, and planning detail:
`/skill:engineering-policy`.
