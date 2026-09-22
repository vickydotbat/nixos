# scratch-guard, which gives every subagent its own scratch folder and refuses
# the shared one.
#
# `/tmp/$CLAUDE_CODE_SESSION_ID` is one directory per session, and a subagent
# inherits the parent's session id. Nine subagents at once means nine writers
# in one folder, all reaching for the same obvious names — `pr-body.md`,
# `out`, `body.md`. Nothing fails loudly when they collide: the file is there,
# it is just the wrong repository's text. Two pull requests have already been
# opened carrying another repository's body that way.
#
# So the fix is mechanical, not a rule to remember:
#
#   SubagentStart  creates /tmp/<session id>/<agent id> and tells the subagent
#                  the path, before it runs a single tool.
#   PreToolUse     refuses a Bash, Write, or Edit call that names the shared
#                  folder from inside a subagent.
#
# The main thread keeps the session folder for itself; the hook sees no
# `agent_id` there and passes. Same install shape as the other guards: a stable
# path Home Manager repoints on every rebuild, and a jq filter that touches
# only this hook's entries so the others coexist.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.scratchGuard;
  hookPath = "${config.home.homeDirectory}/.claude/scratch-guard-hook";

  hook = pkgs.writeShellApplication {
    name = "scratch-guard-hook";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scratch-guard-hook.sh;
  };
in
{
  options.theorem.home.agents.scratchGuard = {
    enable = lib.mkEnableOption "per-subagent scratch folders, enforced";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/scratch-guard-hook".source = "${hook}/bin/scratch-guard-hook";

    home.activation.scratchGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale scratch-guard entry from both events, drop entries left
      # empty, then append the canonical ones. Writing through a temp file
      # keeps the original intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          def strip:
            ((. // [])
             | map(.hooks |= map(select(.command | test("/scratch-guard-hook$") | not)))
             | map(select(.hooks | length > 0)));

          .hooks.PreToolUse = (
            (.hooks.PreToolUse | strip)
            + [{ matcher: "Bash|Write|Edit",
                 hooks: [{ type: "command", command: $hook }] }]
          )
          | .hooks.SubagentStart = (
            (.hooks.SubagentStart | strip)
            + [{ matcher: "*",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
