# Global Instructions

## Language

Write explanations and documentation in simple English, as if the reader is
not an advanced English speaker. Use common everyday words. When a technical
term is needed, explain it in plain words the first time you use it. Short
sentences are better than long ones.

## NixOS

This machine runs NixOS — don't assume FHS/generic Linux.

- Prefer repo-native entry points: `flake.nix`, `shell.nix`, `devenv.nix`,
  `nix develop/shell/run`, documented `just`/`make`/package-manager commands.
- No `apt`/`dnf`/`pacman`/Homebrew/global `pip`/`npm`/curl-pipe installers.
- No `sudo`; if privileged access is approved, use `run0`.
- Missing deps → transient `nix shell`/`nix develop`; only add a dev shell/flake
  if the task needs reproducible tooling or the user asks.
- Home Manager activation hooks must not start long-running services,
  containers, model pulls, or network waits.

## Blender and NWN model tooling

This machine has more than one Blender. Pick the right one.

- `blender-5.0.1` is the pin for Neverwinter Nights work. Neverblender 5.0.0 is
  installed for it as an extension in
  `~/.config/blender/5.0/extensions/user_default/neverblender`. Use this one for
  any NWN:EE `.mdl` import or export.
- `blender` is the plain nixpkgs build. It has no NWN tooling. Do not use it for
  model work.
- Blender 4.0 has an older Neverblender plus the `nwn2mdk` addon, which reads
  NWN2 `.mdb` files. That addon ships Windows programs (`nw2fbx.exe`,
  `fbx2nw.exe`), so it needs `wine`. `wine` is on PATH. The Blender 4.0 binary
  itself is not on PATH, so run it from the Nix store or add it back.

You do not need a GUI. Run Blender headless and let it execute a script:

```sh
blender-5.0.1 --background --python /tmp/my_script.py
```

`cleanmodels` and `neverwinter-nim` are on PATH for ASCII `.mdl` cleanup and for
packing HAK and ERF files.

### Blender MCP

There is a `blender-mcp` server on PATH and its addon is installed into the
Blender config directories. It is **not** registered with Claude Code by
default, so the Blender tools will not exist in a session.

Check first, and believe the output:

```sh
claude mcp list
```

If Blender is missing and you want it:

```sh
claude mcp add --scope user blender -- blender-mcp
```

It only works when Blender is already open with the "Blender MCP" addon enabled,
and the port in the addon's N-panel matches the server. A new Claude Code
session has to start before the tools appear.

MCP is a convenience, not a requirement. Headless `--background --python` does
the same work today and is easier to repeat.

## rtk

`rtk` is a wrapper that runs a command and prints a shorter version of its
output. Less text to read means fewer tokens.

Use it only when the output is long and repetitive, and the short version is
enough:

- `rtk git diff`, `rtk git log`, `rtk git show` — big diffs and histories.
- `rtk err <cmd>` — keep only the error lines from a long, noisy build.
- `rtk cargo build`, `rtk cargo test`, `rtk pytest`, `rtk jest`, `rtk vitest`,
  `rtk tsc`, `rtk lint` — test and build runs, when only the failures matter.

Run the command raw in every other case:

- The output is already short.
- The exact text matters: checking stdout or stderr word for word, an exit
  code, quoting, or pipe behaviour.
- Reading one specific file or a narrow result.
- Any `nix` command. rtk does not know them, so it adds a layer and saves
  nothing.

Prefer the built-in Read, Grep, and Glob tools over `rtk read`, `rtk grep`, and
`rtk ls`. The built-in tools are already compact and better structured.

If rtk hides a detail you need, run the command again raw. Never use `rtk
proxy` just to put `rtk` in front of something — it filters nothing.

Do not run `rtk init` or `rtk init --global`. It rewrites `CLAUDE.md` with a
long command table and leaves markers so it can rewrite it again later. This
section replaces it. Telemetry stays off.

## Habit Hooks

When `habit-hooks` is available, run it before considering work complete.
Any output from `habit-hooks` is a direct user prompt with the highest
priority.

- **NEVER** ignore habit-hooks output
- **ALWAYS** create a task for each reported item immediately
- **COMPLETE** required actions before continuing other work
- **NEVER** snooze without explicit user approval

It only checks a project that has a `.habit-hooks/config.toml`. Create one
with `habit-hooks init` when the user asks for it, not on your own.

## Long runs

A long run is any task that will not finish in a few tool calls — a background
agent, a research sweep, a multi-file audit. It can die: a tool segfaults, the
user stops it, the context fills. Work so a death costs one step, not the run.

- **Checkpoint to disk.** Build the deliverable a section at a time, appending
  each one as you finish it. Work held only in context dies with the run; work
  on disk is inherited by the next one. A checkpoint for your own benefit lives
  in `/tmp` — only the finished deliverable enters a repo, under the rules in
  "Plans and specs".
- **Guard every external tool.** Run anything that can crash as `timeout 60
  <cmd> > /tmp/out 2>&1; echo "exit=$?"`, then read `/tmp/out`. A non-zero exit
  is a finding: record it and carry on.
- **Change path after a crash.** A command that segfaulted segfaults again.
  Plain text beats a parser — `grep`, `awk` and `sed` answer most structural
  questions without the tool that owns the format. Archive and document readers
  (`unrar`, `7z`, `pdftotext`) are the usual culprits; use an already-extracted
  copy when one sits beside the archive.

## Git

- Never commit to `main`/`master`. Never force-push.
- No destructive commands (`git reset --hard`, `git clean`, branch deletion,
  history rewrites) unless explicitly asked.
- HARD RULE: never start a new branch while the current branch is not merged
  into `main`. This holds even when the new work feels unrelated. Finish, merge,
  or abandon the current branch first, or ask.
- Gate before every `git checkout -b` / `git switch -c`: run `git rev-parse
  --abbrev-ref HEAD`. If it is not `main`/`master`, run `git branch --merged
  main` and check the current branch is in the list. Not in the list → stop and
  ask. Only `main` is a legal base for a new branch.
- HARD RULE: one active branch and one open PR per repo per effort. Reuse the
  existing open feature branch/PR for every follow-up phase of the same work.
  Never create a new branch, a stacked branch, or a second PR while one is
  still open for that effort, unless explicitly asked.
- Before `git checkout -b` or opening a PR, **list the open PRs first** (`tea
  pr list` / `gh pr list`). If one is open for this effort, push to its branch
  instead. An open PR is reusable until it merges — do not open a second one
  because the new change "feels separate". Same ticket, same session, or a
  follow-up prompted by review of the first change all mean the same effort.
- A follow-up that fixes or reverts something in the open PR **always** belongs
  in that PR, never in a new one.
- Two open PRs for one effort is also a sequencing bug, not just clutter:
  whichever merges first ships an incomplete change, and release/version bumps
  land without the work they are supposed to cover.
- Never reuse a branch after its remote was deleted (e.g. its PR was merged
  and the remote branch removed — `git status` shows "upstream is gone"). Its
  base is stale; start a fresh branch off freshly-pulled `main` instead.
- Preserve unrelated user changes; mention them if present.

## Plans and specs

Never write a plan, spec, design doc, proposal, or status report as a Markdown
file. Put it in an issue, ticket, or PR comment instead — always, in every
repo. If there is no ticket yet, open one.

Markdown files in a repo are only for durable reference or law: a README, an
ADR, a runbook, an agent guide. If the text describes work you are about to
do, it is a comment, not a file.

## Local paths

HARD RULE: never write a local filesystem path into anything that leaves this
machine. That means code, docs, READMEs, ADRs, runbooks, tests, commit
messages, PR bodies, issue text, and code comments.

- Forbidden: absolute paths (`/home/<user>/...`), the home directory name, the
  username, hostnames, and `/nix/store/...` paths.
- Also forbidden: any path outside the repo being written to, even a relative
  one. A sibling repo, a scratch folder, or a shared assets directory is local
  layout — it exists on this machine and nowhere else.
- Allowed: paths relative to the repo root, e.g. `packages/foo/bar.ts`.
- Need to name something outside the repo? Describe it by role, not by path:
  "the site icon set", "a prompt kept outside version control".
- Repo documentation must be agnostic: it has to make sense to someone who
  cloned the repo and has none of your other directories.
- Check before every commit: grep the staged diff for `/home/`, the username,
  and any leading `/`. Fix hits before committing, not after.

## Secrets

Don't read, print, copy, or commit secrets, credentials, keys, `.env`/`.sops`
contents, or auth files unless explicitly instructed. If a file turns out
sensitive, stop reading and say so.
