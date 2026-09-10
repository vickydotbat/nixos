# rm-guard, a PreToolUse hook that refuses a delete git cannot undo.
#
# Git is the undo button. A tracked file survives `rm -rf`, because the copy in
# the repo is still there. An untracked file does not: once deleted it is gone
# for good. So this hook only stops the second kind.
#
# It looks at a delete when the command is broad enough to take a whole tree
# with it: `rm` with `-r`, `rm` with a wildcard, `shred`, or `find -delete`.
# A single named `rm file` is left alone.
#
# Being listed in .gitignore is not enough to pass. A `.env` is ignored and
# still irreplaceable. Only a name on the `disposable` list below — node_modules
# and friends, which a build command writes again — is treated as throw-away.
# Scratch work under /tmp passes too.
#
# The hook lives at a stable path (~/.claude/rm-guard-hook) that Home Manager
# repoints on every rebuild, and the activation script pins settings.json to
# that path. The jq filter below only strips rm-guard entries, so other hooks
# coexist and the order the activation scripts run in does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.rmGuard;
  hookPath = "${config.home.homeDirectory}/.claude/rm-guard-hook";

  # Matched against each path component, so `src/node_modules/x` passes too.
  disposableRe = lib.concatStringsSep "|" (map lib.escapeRegex cfg.disposable);

  hook = pkgs.writeShellApplication {
    name = "rm-guard-hook";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
    ];
    text = ''
      payload=$(cat)
      command=$(jq -r '.tool_input.command // ""' <<<"$payload")
      cwd=$(jq -r '.cwd // ""' <<<"$payload")

      # Cheap pre-filter: nothing here applies without a delete verb.
      grep -Eq '(^|[^[:alnum:]_-])(rm|shred|find)([[:space:]]|$)' <<<"$command" || exit 0

      if [ -n "$cwd" ]; then
        cd "$cwd" 2>/dev/null || exit 0
      fi

      refuse() {
        printf 'rm-guard: refused. %s\n' "$1" >&2
        shift
        printf '%s\n' "$@" >&2
        exit 2
      }

      # Empty when the path is not inside a repo, so the caller can tell
      # "outside git" from "inside git but untracked".
      worktree_of() {
        git -C "$(dirname -- "$1")" rev-parse --show-toplevel 2>/dev/null
      }

      # A path is safe to delete when nothing under it would be lost. `ls-files
      # --others` lists every file git is not tracking, ignored ones included,
      # because .gitignore holds real work too: a local `.env`, a key, a dump.
      # Only the names on the disposable list are dropped from that answer, and
      # an empty answer means the delete is reversible.
      check_path() {
        local path=$1 top untracked
        [ -e "$path" ] || return 0

        # Make the path absolute before anything else. `git ls-files` reads a
        # pathspec relative to the repo top, not to the shell's directory, so a
        # relative path checked from a subdirectory would look at the wrong
        # place and wave the delete through. `realpath -s` also flattens `..`,
        # which keeps git from seeing a pathspec outside the tree.
        case "$path" in
          /*) ;;
          *) path=$PWD/$path ;;
        esac
        path=$(realpath -s -- "$path" 2>/dev/null) || return 0

        case "$path" in
          /tmp/* | /tmp | "''${TMPDIR:-/tmp}"/*) return 0 ;;
        esac

        top=$(worktree_of "$path") || top=""
        if [ -z "$top" ]; then
          refuse \
            "'$path' is not inside a git repository." \
            "Git cannot restore this, so the delete has to be a deliberate human choice." \
            "Stop and ask the user to run it, or move the work into a repo first."
        fi

        untracked=$(git -C "$top" ls-files --others -- "$path" \
          | grep -Ev '(^|/)(${disposableRe})(/|$)' \
          | head -5) || true
        if [ -n "$untracked" ]; then
          refuse \
            "'$path' holds files git is not tracking:" \
            "$untracked" \
            "" \
            "Deleting them loses them for good, and .gitignore does not make a" \
            "file replaceable. Commit them first, or ask the user to run the delete."
        fi
      }

      # An operand still carries the quotes and the tilde the shell has not
      # eaten yet, because the hook sees the command before it runs.
      clean_operand() {
        local op=$1
        op=''${op//\"/}
        op=''${op//\'/}
        op=''${op/#\~\//$HOME/}
        printf '%s' "$op"
      }

      # Expand a pattern the way the shell would, without running anything.
      # `nullglob` turns a pattern that matches nothing into no words at all,
      # and rm would fail on its own there, so there is nothing to guard.
      #
      # ponytail: the unquoted $op is what does the globbing, so a pattern
      # containing a space is split into two. It only makes the guard check
      # more paths than it should, never fewer.
      expand_operand() {
        local op=$1 match
        case "$op" in
          *[\*\?\[]*)
            shopt -s nullglob
            for match in $op; do printf '%s\n' "$match"; done
            shopt -u nullglob
            ;;
          *) printf '%s\n' "$op" ;;
        esac
      }

      # Split on the usual separators so `foo && rm -rf bar` is seen.
      while IFS= read -r segment; do
        read -ra words <<<"$segment" || true
        [ ''${#words[@]} -gt 0 ] || continue

        # Step over the wrappers that sit in front of the real command, so
        # `sudo rm` and `FOO=1 rm` are still judged as rm.
        #
        # ponytail: `xargs rm` and `sh -c "rm ..."` still slip past. Add them
        # if an agent actually starts reaching for them.
        i=0
        while [ "$i" -lt ''${#words[@]} ]; do
          case "''${words[$i]}" in
            *=* | sudo | run0 | env | command | time | nohup) i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        [ "$i" -lt ''${#words[@]} ] || continue

        verb=''${words[$i]}
        verb=''${verb##*/}
        operands=()
        recursive=0
        globbed=0

        case "$verb" in
          rm | shred)
            for word in "''${words[@]:$((i + 1))}"; do
              case "$word" in
                --) continue ;;
                --recursive | --dir) recursive=1 ;;
                --*) continue ;;
                -*)
                  case "$word" in
                    *[rRd]*) recursive=1 ;;
                  esac
                  continue
                  ;;
              esac
              case "$word" in
                *[\*\?\[]*) globbed=1 ;;
              esac
              operands+=("$(clean_operand "$word")")
            done
            # A single named file is the user's business. Only a delete broad
            # enough to sweep up more than it names gets checked.
            [ "$recursive" -eq 1 ] || [ "$globbed" -eq 1 ] || continue
            ;;

          find)
            grep -Eq '[[:space:]]-(delete|fdelete)([[:space:]]|$)' <<<"$segment" || continue
            # Only the paths before the first predicate are directories.
            for word in "''${words[@]:$((i + 1))}"; do
              case "$word" in
                -*) break ;;
              esac
              operands+=("$(clean_operand "$word")")
            done
            ;;

          *) continue ;;
        esac

        for operand in ''${operands[@]+"''${operands[@]}"}; do
          while IFS= read -r match; do
            [ -n "$match" ] && check_path "$match"
          done < <(expand_operand "$operand")
        done
      done < <(tr ';&|\n' '\n' <<<"$command")

      exit 0
    '';
  };
in
{
  options.theorem.home.agents.rmGuard = {
    enable = lib.mkEnableOption "guard against deletes git cannot undo";

    disposable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "node_modules"
        ".direnv"
        "__pycache__"
        ".pytest_cache"
        ".mypy_cache"
        ".ruff_cache"
        "target"
        "dist"
        "build"
        ".next"
        "result"
      ];
      description = ''
        Path components a build command writes again on its own, so deleting
        them loses nothing. Everything else git is not tracking blocks the
        delete, whether .gitignore lists it or not.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/rm-guard-hook".source = "${hook}/bin/rm-guard-hook";

    home.activation.rmGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale rm-guard entry, drop entries left empty, then append
      # the canonical one. Writing through a temp file keeps the original
      # intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            ((.hooks.PreToolUse // [])
             | map(.hooks |= map(select(.command | test("/rm-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "Bash",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
