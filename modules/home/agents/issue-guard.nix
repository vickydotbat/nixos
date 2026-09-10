# issue-guard, a PreToolUse hook that refuses to read half a thread.
#
# An issue or a pull request is a thread: the body plus every comment. A
# comment often changes what the body means — it narrows the scope, corrects a
# number, or says the plan was dropped. An agent that reads only the body acts
# on the old plan, so this hook stops the detail view that leaves the comments
# behind and names the flag that fetches them.
#
# It only touches a command that opens one issue or one pull request. Listing,
# creating, editing, and `gh api` pass untouched.
#
# The hook lives at a stable path (~/.claude/issue-guard-hook) that Home
# Manager repoints on every rebuild, and the activation script pins
# settings.json to that path. The jq filter below only strips issue-guard
# entries, so other hooks coexist and the order the activation scripts run in
# does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.issueGuard;
  hookPath = "${config.home.homeDirectory}/.claude/issue-guard-hook";

  hook = pkgs.writeShellApplication {
    name = "issue-guard-hook";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      payload=$(cat)
      command=$(jq -r '.tool_input.command // ""' <<<"$payload")

      # Cheap pre-filter: only the two forge CLIs are in scope.
      grep -Eq '(^|[^[:alnum:]_-])(gh|tea)([[:space:]]|$)' <<<"$command" || exit 0

      refuse() {
        printf 'issue-guard: refused. %s\n' "$1" >&2
        printf 'An issue is a thread: body plus every comment, and a comment can change what the body says.\n' >&2
        printf 'Re-run with --comments.\n' >&2
        exit 2
      }

      # One command per segment, so a pipeline or a chain is judged piece by
      # piece rather than as one string.
      while IFS= read -r segment; do
        # Already asking for the comments, in any of the forms that carry them.
        grep -Eq '(^|[[:space:]])(--comments|-c)([[:space:]]|=|$)' <<<"$segment" && continue
        grep -Eq -- '--json[[:space:]=][^[:space:]]*comments' <<<"$segment" && continue
        grep -Eq '(^|[[:space:]])--web([[:space:]]|$)' <<<"$segment" && continue

        # gh names the verb: `gh issue view 12`, `gh pr view 12`.
        if grep -Eq '(^|[^[:alnum:]_-])gh[[:space:]]+(issue|pr)[[:space:]]+view([[:space:]]|$)' <<<"$segment"; then
          refuse "reading an issue without its comments."
        fi

        # tea has no verb for the detail view: an index alone opens the thread.
        # `tea issues list` and `tea pulls create` carry a subcommand instead.
        if grep -Eq '(^|[^[:alnum:]_-])tea[[:space:]]+(issues?|i|pulls?|pr)[[:space:]]+[0-9]+([[:space:]]|$)' <<<"$segment"; then
          refuse "reading an issue without its comments."
        fi
      done < <(tr ';&|\n' '\n' <<<"$command")

      exit 0
    '';
  };
in
{
  options.theorem.home.agents.issueGuard = {
    enable = lib.mkEnableOption "guard against reading an issue without its comments";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/issue-guard-hook".source = "${hook}/bin/issue-guard-hook";

    home.activation.issueGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale issue-guard entry, drop entries left empty, then append
      # the canonical one. Writing through a temp file keeps the original
      # intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            ((.hooks.PreToolUse // [])
             | map(.hooks |= map(select(.command | test("/issue-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "Bash",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
