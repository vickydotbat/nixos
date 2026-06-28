---
name: git-safety
description: Use before editing, branching, committing, pushing, rebasing, merging, deleting branches, changing remotes, or running broad git commands. Enforces branch/worktree safety and prevents destructive git operations without approval.
compatibility: opencode
---

# Git Safety

Before editing, branching, committing, switching branches, or running broad commands, inspect:

```bash
git status --short
git branch --show-current
git diff --stat
```

When relevant:

```bash
git diff --name-only
git log --oneline -5
```

## Rules

- Do not commit unless explicitly asked.
- Do not push unless explicitly asked.
- Do not open PRs unless explicitly asked.
- Do not delete branches unless explicitly asked.
- Do not modify remotes unless explicitly asked.
- Never force-push unless explicitly asked and the exact branch has been confirmed.
- Never commit directly to `main`, `master`, or a protected release branch unless explicitly instructed.
- Work on the current branch unless branch changes were requested.
- If unrelated dirty changes exist, leave them alone and report them. Ask only if they overlap files you must edit or make the requested work ambiguous.
- New branches should start from up-to-date `main` or the repository's configured base branch.
- Do not create stacked branches unless explicitly asked.
- Do not reuse a branch that was merged remotely and deleted unless explicitly asked.
- Keep user changes separate from agent changes.
- Keep commits focused when commits are explicitly requested.

## Destructive Commands

Do not run destructive git commands without explicit approval.

High-risk examples:

- `git reset --hard`
- `git clean`
- `git checkout --`
- `git restore`
- `git rebase`
- `git push --force`
- branch deletion
- remote changes
- history rewriting

If a destructive command seems necessary, explain why and ask first.
