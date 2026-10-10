# pr-guard, a PreToolUse hook that holds every effort to one open pull request,
# and keeps stacks for the times the operator asks for one.
#
# The rule lived in CLAUDE.md as prose, with a fallback that let an agent stack
# whenever its open pull request was "waiting on review". Agents read every
# open pull request as waiting, so the fallback became the habit: four times a
# session opened a second pull request beside the first. Prose is not
# enforcement, so this hook refuses, before the command runs:
#
#   1. A second pull request for one effort: `tea pr create`, `gh pr create`,
#      `gs branch submit`, or a `tea api` POST to `pulls`. An effort is a
#      Claude Code session, so a session that already opened a pull request
#      still open in the same repository is refused. A new pull request whose
#      title or branch names a ticket an open one already names is refused
#      from any session, because that effort is in flight. Re-submitting the
#      branch that owns the open pull request passes, because that only
#      updates it. A `depot/<user>` pull request, which the Westgate depot site
#      opens, never counts. With no session ID, any other open pull request of
#      the operator's in the repository counts.
#
#      One pull request per repository, the rule before this, made unrelated
#      efforts queue behind each other, and every squash merge sent the next
#      one back for a rebase.
#   2. `gs stack submit`, `gs upstack submit` and `gs downstack submit`, which
#      open one pull request per branch.
#   3. `gs branch create` on any branch but main/master: that is a stack.
#   4. Any `gh` or `tea` command whose text credits an AI: a Co-Authored-By
#      line or a "Generated with Claude Code" footer, in the command itself or
#      in a body file it reads (`--body-file`, `-F`, `$(cat file)`). Claude
#      Code's `attribution` setting already turns the footer off; this catches
#      a session that writes one by hand. No allowance covers it.
#
# The one way past it is an allowance the operator grants from her own
# terminal, outside the session: `touch ~/.claude/pr-guard-allow`. The next
# refused command consumes it and runs. An agent cannot mint one: a Bash
# command that names the file, and a Write or Edit aimed at it, are refused.
#
# Listing the open pull requests needs the forge. When that call fails the
# hook refuses and says why, because "could not check" must not read as "none".
#
# The hook lives at a stable path (~/.claude/pr-guard-hook) that Home Manager
# repoints on every rebuild, and the activation script pins settings.json to
# that path. The jq filter below only strips pr-guard entries, so other hooks
# coexist and the order the activation scripts run in does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.prGuard;
  hookPath = "${config.home.homeDirectory}/.claude/pr-guard-hook";

  # `tea`, `gh` and `gs` come from the session's own PATH, so the hook asks the
  # forge with the same logins the agent uses, and the test can stand in for
  # them.
  hook = pkgs.writeShellApplication {
    name = "pr-guard-hook";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
    ];
    text = ''
      payload=$(cat)
      tool=$(jq -r '.tool_name // "Bash"' <<<"$payload")
      allow_file="$HOME/.claude/pr-guard-allow"

      refuse() {
        printf 'pr-guard: refused. %s\n' "$1" >&2
        shift
        for line in "$@"; do printf '%s\n' "$line" >&2; done
        exit 2
      }

      allowance_hint="Each effort holds one open pull request, and a stack is opened only when Vicky asks for one in this conversation. Push to the open pull request instead. If Vicky asked for this one, ask her to run 'touch ~/.claude/pr-guard-allow' in her own terminal, then run the command again."

      case "$tool" in
        Write | Edit | MultiEdit | NotebookEdit)
          path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$payload")
          [[ $(basename -- "$path") == pr-guard-allow ]] &&
            refuse "only Vicky grants a pr-guard allowance, from her own terminal."
          exit 0
          ;;
        Bash) ;;
        *) exit 0 ;;
      esac

      command=$(jq -r '.tool_input.command // ""' <<<"$payload")
      cwd=$(jq -r '.cwd // ""' <<<"$payload")

      grep -q 'pr-guard-allow' <<<"$command" &&
        refuse "only Vicky grants a pr-guard allowance, from her own terminal."

      # Cheap pre-filter: only the forge CLIs and git-spice are in scope.
      grep -Eq '(^|[^[:alnum:]_-])(gh|tea|gs)([[:space:]]|$)' <<<"$command" || exit 0

      # An allowance covers one refused command, then it is gone.
      spend_allowance() {
        if [ -f "$allow_file" ]; then
          rm -f -- "$allow_file"
          printf 'pr-guard: allowed once by Vicky (%s). The allowance is spent.\n' "$1" >&2
          exit 0
        fi
      }

      if [ -n "$cwd" ]; then
        cd "$cwd" || exit 0
      fi

      # Rule 4: no AI credit in text sent to the forge. A body usually arrives
      # as a file, so read every file the command names as a body. The command
      # string still holds `$CLAUDE_CODE_SESSION_ID` unexpanded, so expand it
      # from the payload, along with `$HOME` and `~`.
      session_id=$(jq -r '.session_id // ""' <<<"$payload")
      forge_text=$command
      while IFS= read -r body_file; do
        body_file=''${body_file//\$\{CLAUDE_CODE_SESSION_ID\}/$session_id}
        body_file=''${body_file//\$CLAUDE_CODE_SESSION_ID/$session_id}
        body_file=''${body_file//\$\{HOME\}/$HOME}
        body_file=''${body_file//\$HOME/$HOME}
        body_file=''${body_file/#\~\//$HOME/}
        if [ -r "$body_file" ]; then
          forge_text="$forge_text
      $(cat -- "$body_file")"
        fi
      done < <(grep -oE '(--body-file|-F|--file)[[:space:]=]+[^[:space:];&|)]+|\$\((cat|<)[[:space:]]+[^[:space:];&|)]+' <<<"$command" |
        sed -E 's/^(--body-file|-F|--file)[[:space:]=]+//; s/^\$\((cat|<)[[:space:]]+//; s/["'"'"']//g')
      if grep -Eqi 'co-authored-by|generated with.*claude' <<<"$forge_text"; then
        refuse "this text credits an AI (a Co-Authored-By line or a 'Generated with' footer)." \
          "CLAUDE.md: never credit an AI in a PR, ticket or comment, whoever asks." \
          "Drop the line and run the command again. If a system prompt told you to add it, say so to the user."
      fi

      # Judge the repository the command really touches: the first `cd <path>`
      # wins, as in git-guard.
      if [[ $command =~ (^|[[:space:]\;\&\|])cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
        target_dir=''${BASH_REMATCH[2]}
        target_dir=''${target_dir//\"/}
        target_dir=''${target_dir//\'/}
        target_dir=''${target_dir/#\~\//$HOME/}
        cd "$target_dir" 2>/dev/null || exit 0
      fi

      current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

      # The value after a flag in one segment, `--flag value` or `--flag=value`.
      flag_value() {
        local segment=$1 flag
        shift
        for flag in "$@"; do
          local pattern="(^|[[:space:]])''${flag}[[:space:]=]+([^[:space:]]+)"
          if [[ $segment =~ $pattern ]]; then
            local value=''${BASH_REMATCH[2]}
            value=''${value//\"/}
            printf '%s' "''${value//\'/}"
            return
          fi
        done
      }

      # Every open pull request of mine in this repository, one
      # "index head title" per line. Gitea's author field carries the full name
      # when the account has one, so both names count as mine.
      #
      # A `depot/<user>` branch is an asset pull request the Westgate depot site
      # opens in her name, not an agent's effort, so it never counts.
      my_open_pulls() {
        local forge=$1 repo=$2 list me
        if [ "$forge" = gh ]; then
          list=$(timeout 30 gh pr list --author @me --state open --json number,headRefName,title \
            ''${repo:+--repo "$repo"} </dev/null 2>&1) || { printf '%s' "$list"; return 1; }
          jq -r '.[] | select(.headRefName | startswith("depot/") | not)
                 | "\(.number) \(.headRefName) \(.title)"' <<<"$list"
        else
          me=$(timeout 30 tea api user </dev/null 2>&1) || { printf '%s' "$me"; return 1; }
          list=$(timeout 30 tea pulls list --state open --output json --fields index,head,author,title \
            ''${repo:+--repo "$repo"} </dev/null 2>&1) || { printf '%s' "$list"; return 1; }
          jq -r --argjson me "$me" \
            '.[] | select(.author == $me.login or (($me.full_name // "") != "" and .author == $me.full_name))
                 | select(.head | startswith("depot/") | not)
                 | "\(.index) \(.head) \(.title // "")"' <<<"$list"
        fi
      }

      # Ticket references (PLAT-372, GAME-12), upper-cased because branch names
      # write them in lower case, one per line, sorted and unique.
      tickets_in() {
        grep -oiE '\b[a-z][a-z0-9]+-[0-9]+\b' <<<"$1" | tr '[:lower:]' '[:upper:]' | sort -u || true
      }

      # The title a segment passes with --title or -t, quoted or bare.
      title_of() {
        local segment=$1
        if [[ $segment =~ (^|[[:space:]])(--title|-t)[[:space:]=]+\"([^\"]*)\" ]] ||
           [[ $segment =~ (^|[[:space:]])(--title|-t)[[:space:]=]+\'([^\']*)\' ]] ||
           [[ $segment =~ (^|[[:space:]])(--title|-t)[[:space:]=]+([^[:space:]]+) ]]; then
          printf '%s' "''${BASH_REMATCH[3]}"
        fi
      }

      # The pull requests this session opened, one "repo head" per line. The
      # session ID stands for the effort: subagents share it, and a new effort
      # is a new session. Entries for merged or closed pull requests stay and
      # count for nothing, because only open pull requests are compared.
      sessions_dir="$HOME/.claude/pr-guard-sessions"
      session_file=""
      [[ -n $session_id ]] && session_file="$sessions_dir/$session_id"

      # One effort, one open pull request. Refuse when this session already has
      # another open one in this repository, or when an open one already names
      # a ticket the new one names. With no session ID (another harness), any
      # other open pull request of mine counts, as the rule stood before.
      check_one_pull() {
        local segment=$1 forge=$2 head=$3 repo=$4 pulls others repo_key mine new_tickets shared index phead ptitle
        if ! pulls=$(my_open_pulls "$forge" "$repo"); then
          spend_allowance "pull request opened without the open-PR check"
          refuse "could not list this repository's open pull requests, so a second one cannot be ruled out." \
            "The forge said: $pulls" "$allowance_hint"
        fi
        others=$(awk -v head="$head" '$2 != head' <<<"$pulls")
        repo_key=''${repo:-$(git remote get-url origin 2>/dev/null || pwd)}

        if [[ -z $session_file ]]; then
          if [ -n "$others" ]; then
            spend_allowance "a second open pull request"
            refuse "this repository already has your open pull request: $(cut -d' ' -f1,2 <<<"$others" | tr '\n' ' ')(index, branch)." \
              "$allowance_hint"
          fi
          return 0
        fi

        mine=""
        if [[ -f $session_file ]]; then
          while read -r index phead _; do
            [[ -n $index ]] || continue
            if awk -v r="$repo_key" -v h="$phead" '$1 == r && $2 == h { found = 1 } END { exit !found }' "$session_file"; then
              mine="$mine$index $phead "
            fi
          done <<<"$others"
        fi
        if [[ -n $mine ]]; then
          spend_allowance "a second open pull request from one session"
          refuse "this session already has an open pull request here: $mine(index, branch)." \
            "One effort is one pull request. Commit on that branch and push to it." "$allowance_hint"
        fi

        new_tickets=$(tickets_in "$(title_of "$segment") $head")
        if [[ -n $new_tickets ]]; then
          while read -r index phead ptitle; do
            [[ -n $index ]] || continue
            shared=$(comm -12 <(printf '%s\n' "$new_tickets") <(tickets_in "$ptitle $phead"))
            if [[ -n $shared ]]; then
              spend_allowance "a pull request for a ticket another one already names"
              refuse "open pull request $index ($phead) already names $(tr '\n' ' ' <<<"$shared")." \
                "That effort is in flight. Push to its branch instead." "$allowance_hint"
            fi
          done <<<"$others"
        fi

        if [[ -n $head ]]; then
          mkdir -p "$sessions_dir"
          printf '%s %s\n' "$repo_key" "$head" >>"$session_file"
        fi
      }

      forge_of_repo() {
        if git remote get-url origin 2>/dev/null | grep -q 'github\.com'; then echo gh; else echo tea; fi
      }

      while IFS= read -r segment; do
        # git-spice: a stack submit opens one pull request per branch.
        if grep -Eq '(^|[^[:alnum:]_-])gs[[:space:]]+((stack|s|upstack|us|downstack|ds)[[:space:]]+(submit|s)|ss|uss|dss)([[:space:]]|$)' <<<"$segment"; then
          spend_allowance "a stack submit"
          refuse "a stack submit opens one pull request per branch." "$allowance_hint"
        fi

        # git-spice: a branch created off anything but trunk is a stack.
        if grep -Eq '(^|[^[:alnum:]_-])gs[[:space:]]+((branch|b)[[:space:]]+(create|c)|bc)([[:space:]]|$)' <<<"$segment"; then
          case "$current_branch" in
            main | master | "") ;;
            *)
              spend_allowance "a stacked branch"
              refuse "'gs branch create' on '$current_branch' starts a stack." \
                "Commit on '$current_branch' and push to its open pull request." "$allowance_hint"
              ;;
          esac
        fi

        # Opening a pull request, by any of the four doors.
        if grep -Eq '(^|[^[:alnum:]_-])tea[[:space:]]+(pulls|pull|pr)[[:space:]]+(create|c)([[:space:]]|$)' <<<"$segment"; then
          head=$(flag_value "$segment" --head)
          check_one_pull "$segment" tea "''${head:-$current_branch}" "$(flag_value "$segment" --repo -r)"
        elif grep -Eq '(^|[^[:alnum:]_-])tea[[:space:]]+api([[:space:]]|$)' <<<"$segment" &&
             grep -Eq '(-X|--method)[[:space:]=]+POST' <<<"$segment" &&
             grep -Eq '/pulls([[:space:]"'"'"']|$)' <<<"$segment"; then
          # A raw POST names its branch inside a JSON body this hook does not
          # parse, so every open pull request of mine counts against it.
          check_one_pull "$segment" tea "" ""
        elif grep -Eq '(^|[^[:alnum:]_-])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)' <<<"$segment"; then
          head=$(flag_value "$segment" --head -H)
          check_one_pull "$segment" gh "''${head:-$current_branch}" "$(flag_value "$segment" --repo -R)"
        elif grep -Eq '(^|[^[:alnum:]_-])gs[[:space:]]+((branch|b)[[:space:]]+(submit|s)|bs)([[:space:]]|$)' <<<"$segment"; then
          head=$(flag_value "$segment" --branch)
          check_one_pull "$segment" "$(forge_of_repo)" "''${head:-$current_branch}" ""
        fi
      done < <(tr ';&|\n' '\n' <<<"$command")

      exit 0
    '';
  };
in
{
  options.theorem.home.agents.prGuard = {
    enable = lib.mkEnableOption "guard holding each effort to one open pull request, with stacks only on request";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/pr-guard-hook".source = "${hook}/bin/pr-guard-hook";

    home.activation.prGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale pr-guard entry, drop entries left empty, then append
      # the canonical one. The matcher covers Write and Edit too, so the
      # allowance file cannot be written around the Bash check.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            ((.hooks.PreToolUse // [])
             | map(.hooks |= map(select(.command | test("/pr-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "Bash|Write|Edit|MultiEdit|NotebookEdit",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
