# git-guard, a PreToolUse hook that enforces the two git rules in CLAUDE.md
# that agents keep ignoring, because prose is not enforcement:
#
#   1. No new branch while the current branch is not merged into main/master.
#   2. No push that lands on main/master.
#
# Registered the same way as dcg.nix: the hook lives at a stable path
# (~/.claude/git-guard-hook) that Home Manager repoints on every rebuild, and
# the activation script pins settings.json to that path. The jq filter below
# only strips git-guard entries (and the older branch-guard name) while dcg's
# only strips dcg entries, so the two hooks coexist and the order the
# activation scripts run in does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.gitGuard;
  hookPath = "${config.home.homeDirectory}/.claude/git-guard-hook";

  hook = pkgs.writeShellApplication {
    name = "git-guard-hook";
    runtimeInputs = [
      pkgs.jq
      pkgs.git
    ];
    text = ''
      payload=$(cat)
      command=$(jq -r '.tool_input.command // ""' <<<"$payload")
      cwd=$(jq -r '.cwd // ""' <<<"$payload")

      # Cheap pre-filter: nothing here applies unless the command creates a
      # branch or pushes.
      grep -Eq 'git[[:space:]]' <<<"$command" || exit 0

      if [ -n "$cwd" ]; then
        cd "$cwd" || exit 0
      fi
      git rev-parse --git-dir >/dev/null 2>&1 || exit 0

      # Empty on a detached HEAD.
      current=$(git symbolic-ref --short -q HEAD) || current=""

      refuse() {
        printf 'git-guard: refused. %s\n' "$1" >&2
        shift
        printf '%s\n' "$@" >&2
        exit 2
      }

      # --- Rule 1: no new branch on top of unmerged work ------------------
      #
      # The creation flag may sit anywhere after the subcommand, so
      # `git checkout -q -b x` is caught too, while `git checkout feature-b`
      # is not.
      #
      # ponytail: `git branch x && git switch x` and `git worktree add -b`
      # still slip past. Add them if an agent actually starts using them.
      if grep -Eq 'git[[:space:]].*(checkout|switch)[[:space:]](.*[[:space:]])?-([bBcC]|-create)([[:space:]]|$)' \
        <<<"$command"; then

        base=""
        for candidate in main master; do
          if git rev-parse --verify --quiet "refs/heads/$candidate" >/dev/null; then
            base=$candidate
            break
          fi
        done

        # No main/master, or a detached HEAD: nothing to compare, allow.
        if [ -n "$base" ] && [ -n "$current" ] && [ "$current" != "$base" ]; then
          merged=$(git branch --merged "$base" --format='%(refname:short)')
          if ! grep -Fxq "$current" <<<"$merged"; then
            refuse \
              "you are on '$current', which is not merged into '$base'." \
              "Do not start a new branch on top of unmerged work, even if it feels unrelated." \
              "" \
              "Land the PR for '$current' first, or commit this change on '$current' if it" \
              "belongs to the same effort. Otherwise stop and ask the user."
          fi
        fi
      fi

      # --- Rule 2: nothing lands on main/master ---------------------------
      #
      # Split the command on the usual separators so `foo && git push` is seen,
      # then walk each segment's words looking for `push` and what it targets.
      while IFS= read -r segment; do
        grep -Eq '(^|[[:space:]])git([[:space:]]|$)' <<<"$segment" || continue
        read -ra words <<<"$segment"

        seen_push=0
        remote=""
        refspecs=()
        for word in ''${words[@]+"''${words[@]}"}; do
          if [ "$seen_push" -eq 0 ]; then
            if [ "$word" = "push" ]; then
              seen_push=1
            fi
            continue
          fi

          # --all and --mirror push every branch, main included.
          case "$word" in
            --all | --mirror)
              refuse \
                "'$word' pushes main/master along with everything else." \
                "Push the one branch you mean by name instead."
              ;;
            # ponytail: a flag that takes a separate value (-o, --repo) would be
            # misread as the remote. Harmless: it only makes the guard skip.
            -*) continue ;;
          esac

          if [ -z "$remote" ]; then
            remote=$word
          else
            refspecs+=("$word")
          fi
        done

        [ "$seen_push" -eq 1 ] || continue

        # No refspec means "push the branch I am on".
        targets=()
        if [ ''${#refspecs[@]} -eq 0 ]; then
          [ -n "$current" ] && targets=("$current")
        else
          for spec in "''${refspecs[@]}"; do
            # Destination is whatever follows the last colon: `main`,
            # `HEAD:main`, `+main:main` and `:main` all reduce to `main`.
            dest=''${spec##*:}
            dest=''${dest#+}
            dest=''${dest#refs/heads/}
            # `git push origin "main"` keeps its quotes after word splitting.
            dest=''${dest//\"/}
            dest=''${dest//\'/}
            if [ "$dest" = "HEAD" ]; then
              dest=$current
            fi
            [ -n "$dest" ] && targets+=("$dest")
          done
        fi

        for target in ''${targets[@]+"''${targets[@]}"}; do
          case "$target" in
            main | master)
              refuse \
                "this push lands on '$target'." \
                "Never push to main/master. Push your feature branch and open a PR:" \
                "  git push -u ''${remote:-origin} <your-branch>" \
                "" \
                "If the work is already committed on '$target' locally, stop and ask the user."
              ;;
          esac
        done
      done < <(tr ';&|' '\n' <<<"$command")

      exit 0
    '';
  };
in
{
  options.theorem.home.agents.gitGuard = {
    enable = lib.mkEnableOption "git branch and push guard hook for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/git-guard-hook".source = "${hook}/bin/git-guard-hook";

    home.activation.gitGuardClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale git-guard entry (including the older branch-guard name),
      # drop entries left empty, then append the canonical one. Writing through
      # a temp file keeps the original intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        '
          .hooks.PreToolUse = (
            ((.hooks.PreToolUse // [])
             | map(.hooks |= map(select(.command | test("/(git|branch)-guard-hook$") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "Bash",
                 hooks: [{ type: "command", command: $hook }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
