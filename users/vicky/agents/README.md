# Vicky Agent Configuration

This directory is Vicky's declared agent kit. It is user-owned Home Manager
configuration, not a shared theorem module.

## Layout

- `all/CLAUDE.md` is installed as `~/.claude/CLAUDE.md`, the global doctrine
  every Claude Code session loads. Edit it here, never in `$HOME`: the copy
  there is a read-only link into the Nix store.
- Skills under `all/skills/` are installed into `~/.agents/skills/` and
  `~/.claude/skills/` only when listed in the `skills` set in
  `users/vicky/profiles/agents.nix`. Today that is `vicky-voice` alone.
- `codex/*` is installed into `~/.codex/` when Codex is enabled.
- `claude/*` is installed into `~/.claude/` when Claude Code is enabled.
- `opencode/*` is installed into `~/.config/opencode/` when OpenCode is
  enabled.
- `pi/agent/*` and `pi/extensions/*` are seeded into Pi's mutable
  `~/.pi/agent/` tree when Pi is enabled.

Use `all` only for harness-neutral mechanisms. Put tool-specific prompt files,
commands, agents, or config fragments under the harness that reads them. That
keeps the repair surface legible: shared doctrine in one place, adapter rites
beside the tool that needs them.
