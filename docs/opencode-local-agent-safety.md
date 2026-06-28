# OpenCode Local Agent Safety

OpenCode is allowed to be useful here, not sovereign. Stronger models may plan,
review, and judge commit readiness. GLM/z.ai and other unstable local or cloud
models are bounded workers only.

## Routing Doctrine

- `build` uses `qwen3-coder:480b-cloud` for normal implementation work.
- `plan` and `reviewer` use `kimi-k2.7-code:cloud` for planning and diff
  review.
- `glm-worker` uses `glm-5.2:cloud` only as a subagent with four steps,
  low temperature, no subagent dispatch, no autonomous commits, and stricter
  permissions.
- GLM must finish one named task, summarize, and stop. If tests fail, it
  reports the failure and stops.

The OpenCode Home module writes `~/.config/opencode/safety.json` and exports
`OPENCODE_CONFIG` so OpenCode merges that safety overlay over the normal user
config. Provider credentials and plugin setup stay out of Nix; routing,
permissions, model limits, and bounded worker agents live in the theorem. The
GLM limits are intentionally conservative because the displayed context can
diverge from provider behavior when the reasoning stream degrades.

## Permission Boundary

The safety overlay allows read-only repository discovery and asks before edits,
heavier validation, or privilege boundaries. It denies or
approval-gates the sharp tools:

- `git commit` requires approval.
- `git push`, `git reset --hard`, `git clean`, and `rm -rf` are denied.
- Broad `mv`, `chmod`, and `chown` are approval-gated globally and denied for
  `glm-worker`.
- Common secret paths are denied, including `.sops`, `secrets/`,
  `/run/secrets`, `/run/agenix`, SSH material, and OpenCode auth files.

These permissions are a guardrail, not proof. Review `git diff` before any
commit.

## Watchdog

Run risky or GLM sessions through:

```bash
opencode-watchdog -- opencode
```

For non-interactive runs, put the OpenCode command after `--`:

```bash
opencode-watchdog -- opencode run --agent glm-worker "Implement exactly one named task..."
```

The watchdog logs the terminal stream under:

```text
$XDG_STATE_HOME/opencode/watchdog/
```

or, when `XDG_STATE_HOME` is unset:

```text
~/.local/state/opencode/watchdog/
```

It aborts only on strong corruption signals: symbol-heavy token soup, repeated
raw reasoning/tool markup, malformed tool-call retry loops, or replacement
character stream damage. On detection it stops OpenCode, prints
`SESSION CORRUPTED / DO NOT COMMIT`, shows the log path, and runs
`git status --short`.

## Debug Logs

Use OpenCode's debug logging when reproducing a failure:

```bash
OPENCODE_LOG_LEVEL=DEBUG opencode-watchdog -- opencode
```

Keep provider credentials out of prompts, logs, and examples. If a debug log
might contain secret material, inspect it locally and do not paste it into an
agent session.

## Recovery Rite

After a corrupted session:

1. Stop the session and do not commit.
2. Inspect the watchdog log path printed by the abort.
3. Run `git status --short` and inspect `git diff`.
4. Revert bad hunks manually. Do not use broad reset unless you mean to discard
   all local work.
5. Rerun the narrow checks for the touched files.
6. Continue only with a clean prompt and a reliable supervisor/reviewer model.

The useful artifact after a GLM worker run is the diff, not the worker's
confidence. Send that diff through `/review-glm-diff` before any commit
decision.
