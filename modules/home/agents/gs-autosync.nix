# gs-autosync, a SessionStart hook that keeps a git-spice stack honest without
# anyone remembering to.
#
# The failure it exists for: a forge that squash-merges rewrites a branch's
# commits, so the branch is no longer an ancestor of the trunk even though
# every line of it landed. A plain rebase replays the now-duplicated work and
# conflicts on every line it touched. `gs repo sync` asks the forge what merged
# instead, drops those branches, and retargets their children.
#
# Two things this hook learned the hard way, both in the script below. A branch
# whose pull request was opened with `tea` has no change request git-spice can
# ask about, so a deleted upstream is the only signal that it merged — untrack
# on that, or the next session replays it forever. And a restack that conflicts
# leaves a detached HEAD mid-rebase, which a session-start hook must never hand
# back to the operator.
#
# The hook lives at a stable path (~/.claude/gs-autosync-hook) that Home
# Manager repoints on every rebuild, and the activation script pins
# settings.json to it. The jq filter only strips gs-autosync entries, including
# the hand-written `hooks/gs-autosync.sh` this module replaced, so other
# SessionStart hooks coexist and activation order does not matter.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.gsAutosync;
  hookPath = "${config.home.homeDirectory}/.claude/gs-autosync-hook";

  hook = pkgs.writeShellApplication {
    name = "gs-autosync-hook";
    runtimeInputs = with pkgs; [
      coreutils
      git
      git-spice
      gnugrep
    ];

    # `errexit` is deliberately absent. The script is written as a series of
    # `[[ condition ]] && exit 0` gates, and under `errexit` a gate that simply
    # does not apply is a non-zero compound command that kills the run. The
    # checks below each handle their own failure.
    bashOptions = [
      "nounset"
      "pipefail"
    ];

    text = ''
      git rev-parse --git-dir >/dev/null 2>&1 || exit 0
      # git-spice keeps its state in its own ref. No ref, no stack, nothing to do.
      git rev-parse --quiet --verify refs/spice/data >/dev/null 2>&1 || exit 0

      git_dir="$(git rev-parse --git-dir)"
      # A rebase, merge or bisect in flight owns the worktree. Leave it alone.
      for state in rebase-merge rebase-apply MERGE_HEAD BISECT_LOG CHERRY_PICK_HEAD; do
        [[ -e "$git_dir/$state" ]] && exit 0
      done
      # Uncommitted work: a restack would rebase the branch under it.
      [[ -n "$(git status --porcelain --untracked-files=no)" ]] && exit 0

      start_branch="$(git rev-parse --abbrev-ref HEAD)"

      # git-spice drops a branch only when the forge says its change request
      # merged. A branch submitted with `tea` has no change request, so a squash
      # merge leaves it tracked for good: gs cannot see its content already in
      # the trunk, and every session replays it and conflicts on every line the
      # squash carried. A deleted upstream is the signal gs is missing, so read
      # that instead.
      while read -r tracked; do
        [[ -n "$tracked" ]] || continue
        [[ "$(git for-each-ref --format='%(upstream:track)' "refs/heads/$tracked")" == "[gone]" ]] || continue
        gs branch untrack "$tracked" >/dev/null 2>&1 &&
          printf 'git-spice: %s has no upstream left and was untracked\n' "$tracked"
      done < <(git ls-tree --name-only refs/spice/data:branches 2>/dev/null)

      # A restack that conflicts leaves a detached HEAD mid-rebase. A
      # session-start hook must hand the worktree back the way it found it, and
      # say what happened.
      safe_restack() {
        local out
        out="$(gs stack restack 2>&1)" && { printf '%s' "$out"; return 0; }
        if [[ -e "$git_dir/rebase-merge" || -e "$git_dir/rebase-apply" ]]; then
          git rebase --abort 2>/dev/null
          git switch --quiet "$start_branch" 2>/dev/null
        fi
        printf 'git-spice: restack failed and was rolled back\n%s\n' "$out" >&2
        return 1
      }

      before="$(git ls-tree --name-only refs/spice/data:branches 2>/dev/null)"

      sync_out="$(gs repo sync 2>&1)" || {
        # No forge: not logged in, no network, or the forge is down. Everything
        # that does not need one still runs — fetch, fast-forward the trunk,
        # replay the stack on it. What is lost is only the forge's answer to
        # "what merged", so a branch whose pull request landed stays in the
        # stack until someone says so.
        git fetch --quiet --prune origin 2>/dev/null
        trunk="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
        trunk="''${trunk#origin/}"
        [[ -n "$trunk" ]] || trunk=main
        if [[ "$(git rev-parse --abbrev-ref HEAD)" == "$trunk" ]]; then
          git merge --quiet --ff-only "origin/$trunk" 2>/dev/null
        else
          git fetch --quiet origin "$trunk:$trunk" 2>/dev/null
        fi
        offline_restack="$(safe_restack)" || offline_restack=""
        if [[ "$(printf '%s' "$offline_restack" | grep -c 'restacked on')" -gt 0 ]]; then
          printf 'git-spice: replayed the stack on %s without the forge\n' "$trunk"
        fi
        # The backticks below are literal, not command substitution.
        # shellcheck disable=SC2016
        case "$sync_out" in
          *"not logged in"*)
            printf 'git-spice: run `gs auth login` to let it drop merged branches too\n' ;;
          *)
            printf 'git-spice: no forge this session (%s)\n' "$(printf '%s' "$sync_out" | tail -n1)" ;;
        esac
        exit 0
      }

      after="$(git ls-tree --name-only refs/spice/data:branches 2>/dev/null)"
      dropped="$(comm -23 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after" | sort) | paste -sd' ')"

      restack_out="$(safe_restack)" || restack_out=""
      restacked="$(printf '%s' "$restack_out" | grep -c 'restacked on' || true)"

      [[ -n "$dropped" ]] && printf 'git-spice: %s merged and was dropped\n' "$dropped"
      [[ "$restacked" -gt 0 ]] && printf 'git-spice: %s branch(es) replayed onto their new base\n' "$restacked"
      exit 0
    '';
  };
in
{
  options.theorem.home.agents.gsAutosync = {
    enable = lib.mkEnableOption "git-spice stack sync at Claude Code session start";

    timeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = ''
        Seconds Claude Code waits for the hook before giving up on it. The work
        is a fetch and a replay, so the bound is there to keep a slow or
        unreachable forge from holding up the session.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/gs-autosync-hook".source = "${hook}/bin/gs-autosync-hook";

    home.activation.gsAutosyncClaudeHook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="${config.home.homeDirectory}/.claude/settings.json"

      $DRY_RUN_CMD mkdir -p "$(dirname "$settings")"
      [ -s "$settings" ] || $DRY_RUN_CMD echo '{}' > "$settings"

      # Strip any stale gs-autosync entry, drop groups left empty, then append
      # the canonical one. Writing through a temp file keeps the original
      # intact if jq chokes.
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg hook ${lib.escapeShellArg hookPath} \
        --argjson timeout ${toString cfg.timeout} \
        '
          .hooks.SessionStart = (
            ((.hooks.SessionStart // [])
             | map(.hooks |= map(select(.command | test("gs-autosync") | not)))
             | map(select(.hooks | length > 0)))
            + [{ matcher: "*",
                 hooks: [{ type: "command", command: $hook, timeout: $timeout }] }]
          )
        ' "$settings" > "$settings.tmp" \
        && $DRY_RUN_CMD mv "$settings.tmp" "$settings"
    '';
  };
}
