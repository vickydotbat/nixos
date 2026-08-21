# recap-guard, a Stop hook that makes the agent re-check the stale-able claims
# in its own closing summary before the user reads them.
#
# The failure it exists for: an agent does real work, verifies things as it
# goes, and then writes a recap that repeats a fact from earlier in the session
# as if it were still true. "PR !149 is still open and blocked" — it was, an
# hour and several merges ago. The work was right; the summary was stale. Prose
# rules do not catch this, because the agent is not guessing, it is remembering.
#
# So: when a finished response asserts the state of something mutable and
# external — a PR, an issue, a branch, a test run — block the stop once and hand
# the matched phrases back. The agent then re-checks with a command or deletes
# the claim, and the second stop goes through untouched.
#
# Registered the same way as dcg.nix and git-guard.nix: the hook lives at a
# stable path (~/.claude/recap-guard-hook) that Home Manager repoints on every
# rebuild, and the activation script pins settings.json to that path. The jq
# filter strips only recap-guard entries, so all three hooks coexist and the
# order their activation scripts run in does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.recapGuard;
  hookPath = "${config.home.homeDirectory}/.claude/recap-guard-hook";

  # Claims about mutable external state. Deliberately narrow: a summary that
  # describes what the agent DID ("moved 818 entries", "added a column") is not
  # stale-able and must not trip this. What goes stale is the state of something
  # somebody else can change between the check and the sentence.
  #
  # ponytail: one flat ERE, not a rule engine. Add a branch when a real miss
  # shows up, not in anticipation of one.
  claimPattern = lib.concatStringsSep "|" [
    # "is still open", "was merged", "remains blocked"
    "(is|are|was|were|remains?)[[:space:]]+(still[[:space:]]+)?(open|closed|merged|unmerged|blocked|pending|green|passing|failing)"
    # "still open", "now merged", "currently failing"
    "(still|now|currently)[[:space:]]+(open|closed|merged|blocked|failing|passing|green)"
    # "two open PRs", "no open issues"
    "(one|two|three|four|five|no|[0-9]+)[[:space:]]+open[[:space:]]+(prs?|pull[[:space:]]requests?|issues?|tickets?|branches?)"
    # "blocked on sow-tools#122"
    "blocked[[:space:]]+(on|by)"
    # "250/250 pass", "all tests pass"
    "[0-9]+/[0-9]+[[:space:]]+(pass|passing|green|ok)"
    "all[[:space:]]+(tests|checks)[[:space:]]+(pass|passing|green)"
  ];

  hook = pkgs.writeShellApplication {
    name = "recap-guard-hook";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      payload=$(cat)

      # Every read below fails OPEN. writeShellApplication sets `set -euo
      # pipefail`, so a jq that chokes on an unexpected payload would abort the
      # script with jq's own exit code — and a Stop hook exiting non-zero is
      # read as "block", which would wedge the session on malformed input. The
      # `|| echo` defaults and the explicit `if` forms keep every failure path
      # at exit 0. Refusing to answer is fine; jamming the session is not.
      #
      # Loop guard, and the reason this is safe to run on every turn: a blocked
      # stop re-enters with stop_hook_active=true, so the agent gets exactly one
      # nudge per response and can never talk to itself forever.
      if [ "$(jq -r '.stop_hook_active // false' <<<"$payload" 2>/dev/null || echo false)" = "true" ]; then
        exit 0
      fi

      transcript=$(jq -r '.transcript_path // ""' <<<"$payload" 2>/dev/null || echo "")
      if [ -z "$transcript" ] || [ ! -r "$transcript" ]; then
        exit 0
      fi

      # Last assistant record that actually said something. Records whose
      # content is pure tool_use are skipped, so this is the text the user is
      # about to read.
      #
      # -c keeps each record's text on ONE line as a JSON string, so `tail -n 1`
      # picks the last message rather than the last N lines of several. The
      # second jq decodes that string back to plain text.
      last=$(
        jq -c 'select(.type == "assistant")
               | select(any(.message.content[]?; .type == "text"))
               | [.message.content[] | select(.type == "text") | .text]
               | join("\n")' "$transcript" 2>/dev/null \
          | tail -n 1 | jq -r '. // ""' 2>/dev/null || echo ""
      )
      if [ -z "$last" ]; then
        exit 0
      fi

      # grep exits 1 on no match, which is the common case, so it needs the
      # same fail-open treatment as everything above.
      matches=$(grep -Eino ${lib.escapeShellArg claimPattern} <<<"$last" 2>/dev/null | head -6 || echo "")
      if [ -z "$matches" ]; then
        exit 0
      fi

      {
        printf 'recap-guard: hold on. Your closing message asserts external state:\n\n'
        printf '%s\n' "$matches" | sed 's/^/  /'
        printf '\n'
        printf 'Those are claims about things other people move — PR and issue state,\n'
        printf 'branch state, CI results. You may be repeating what was true earlier in\n'
        printf 'the session rather than what is true now.\n\n'
        printf 'For each one: re-check it with a command, or cut the sentence. A recap\n'
        printf 'that only says what you did needs no verification; a recap that tells\n'
        printf 'the user where things stand does.\n\n'
        printf 'If you already verified it this turn, say so and finish — this fires\n'
        printf 'once per response and will not stop you again.\n'
      } >&2
      exit 2
    '';
  };
in
{
  options.theorem.home.agents.recapGuard = {
    enable = lib.mkEnableOption "closing-summary staleness check for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/recap-guard-hook".source = "${hook}/bin/recap-guard-hook";

    home.activation.recapGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale recap-guard entry, drop entries left empty, then append
      # the canonical one. Writing through a temp file keeps the original intact
      # if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.Stop = (
            ((.hooks.Stop // [])
             | map(.hooks |= map(select(.command | test("/recap-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
