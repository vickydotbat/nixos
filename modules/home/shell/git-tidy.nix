{
  config,
  lib,
  pkgs,
  ...
}:
# Dead branches and orphaned autostashes are the sediment a long-lived checkout
# collects. Neither is dangerous on its own; together they are how a rebase
# replays work that already landed, and how a tired operator finds a detached
# HEAD with no explanation.
#
# This is the narrow, unattended half of the cleanup. The `git gone-prune`
# alias in `git.nix` stays the wide one, and stays manual: it deletes on the
# strength of a missing upstream alone. The rite here deletes only what it can
# prove is already in the trunk, and every deletion leaves a recovery ref
# behind.
let
  cfg = config.theorem.home.shell.git-tidy;

  gitTidy = pkgs.writeShellApplication {
    name = "git-tidy";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      git
      git-spice
    ];
    text = ''
      # Roots to walk, and the age past which an autostash is sediment rather
      # than someone's interrupted afternoon.
      roots=(${lib.concatMapStringsSep " " lib.escapeShellArg cfg.roots})
      stash_age_days=${toString cfg.stashAge}

      dry_run=0
      if [[ "''${1:-}" == "--dry-run" ]]; then
        dry_run=1
      fi

      # A branch is safe to delete when the trunk already carries its content.
      # Two shapes qualify. A merge commit leaves the branch an ancestor of the
      # trunk. A squash merge does not: it rewrites the work as one new commit,
      # so the branch tip is unreachable from the trunk even though every line
      # of it landed. The second test builds that same squash locally — the
      # branch's tree on top of its merge base — and asks `git cherry` whether
      # an equivalent patch is already upstream. Anything else, including a
      # branch that gained local commits after its pull request merged, fails
      # both tests and is kept.
      branch_landed() {
        local branch=$1 trunk=$2 base squash
        git merge-base --is-ancestor "$branch" "$trunk" && return 0
        base=$(git merge-base "$trunk" "$branch") || return 1
        squash=$(git commit-tree "$branch^{tree}" -p "$base" -m tidy) || return 1
        [[ "$(git cherry "$trunk" "$squash")" == -* ]]
      }

      # Name the trunk, and the ref to compare against, in one answer.
      #
      # The comparison uses the remote-tracking ref the fetch above just
      # refreshed. A clone that never checked the trunk out has no local branch
      # for it at all, and one that did may be behind — either way, asking the
      # local copy whether the work landed gets the wrong answer.
      #
      # `origin/HEAD` is the remote's own answer, so it is tried first. It is
      # also a cached symbolic ref: a repository whose trunk was renamed keeps
      # naming the old branch until someone refreshes it. A target that no
      # longer resolves therefore falls through to the probe rather than
      # sending the whole repository to the "no trunk" skip.
      trunk_of() {
        local name ref
        local -a candidates=()

        if name=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
          candidates+=("''${name#origin/}")
        fi
        candidates+=(main master)

        for name in "''${candidates[@]}"; do
          for ref in "refs/remotes/origin/$name" "refs/heads/$name"; do
            if git rev-parse --quiet --verify "$ref" >/dev/null; then
              printf '%s %s\n' "$name" "$ref"
              return 0
            fi
          done
        done
        return 1
      }

      tidy_branches() {
        local repo=$1 trunk=$2 trunk_ref=$3 current branch track tip
        current=$(git symbolic-ref --quiet --short HEAD || true)

        while read -r branch track; do
          [[ "$track" == "[gone]" ]] || continue
          [[ "$branch" != "$current" ]] || continue
          [[ "$branch" != "$trunk" ]] || continue

          if ! branch_landed "$branch" "$trunk_ref"; then
            printf '%s: %s has commits the trunk does not carry, kept\n' "$repo" "$branch"
            continue
          fi

          if (( dry_run )); then
            printf '%s: would delete %s\n' "$repo" "$branch"
            continue
          fi

          # The recovery ref first, always. A deleted branch whose commits are
          # unreachable is one `git gc` away from gone; a ref under
          # `refs/tidy/` keeps them alive until someone says otherwise.
          tip=$(git rev-parse "$branch")
          git update-ref "refs/tidy/branches/$branch" "$tip"

          # git-spice tracks a branch in its own store. Deleting the branch
          # without untracking it leaves the orphaned record that makes the
          # next session replay merged work.
          if git cat-file -e "refs/spice/data:branches/$branch" 2>/dev/null; then
            gs branch untrack "$branch" >/dev/null 2>&1 || true
          fi

          git branch -D "$branch" >/dev/null
          printf '%s: deleted %s (recover with: git branch %s refs/tidy/branches/%s)\n' \
            "$repo" "$branch" "$branch" "$branch"
        done < <(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads)
      }

      # Only entries git itself wrote during a rebase, and only once they are
      # old enough that nobody is coming back for them. A stash the operator
      # named is never touched: the name is the evidence that it was deliberate.
      tidy_stashes() {
        local repo=$1 cutoff entry gd sha ct msg i
        local -a doomed=()
        cutoff=$(( $(date +%s) - stash_age_days * 86400 ))

        while IFS=$'\t' read -r gd sha ct msg; do
          [[ "$msg" == "autostash" ]] || continue
          (( ct < cutoff )) || continue
          doomed+=("$gd $sha")
        done < <(git stash list --format='%gd%x09%H%x09%ct%x09%gs')

        # Highest index first. Dropping a stash renumbers everything below it,
        # so walking the other way would drop the wrong entries.
        for (( i = ''${#doomed[@]} - 1; i >= 0; i-- )); do
          entry=''${doomed[i]}
          gd=''${entry%% *}
          sha=''${entry##* }

          if (( dry_run )); then
            printf '%s: would drop %s (%s)\n' "$repo" "$gd" "''${sha:0:9}"
            continue
          fi

          # The index shifted under us if this no longer resolves to the same
          # commit. Stop rather than drop someone else's work.
          if [[ "$(git rev-parse --quiet --verify "$gd" || true)" != "$sha" ]]; then
            printf '%s: stash list moved while tidying, stopped\n' "$repo" >&2
            return 0
          fi

          git update-ref "refs/tidy/stash/$sha" "$sha"
          git stash drop --quiet "$gd"
          printf '%s: dropped autostash %s (recover with: git stash apply refs/tidy/stash/%s)\n' \
            "$repo" "''${sha:0:9}" "$sha"
        done
      }

      tidy_repo() {
        local repo=$1 git_dir state trunk trunk_ref
        cd "$repo" || return 0
        git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 0

        # A rebase, merge or bisect in flight owns the worktree. The refs are
        # mid-flight and the operator is mid-thought. Leave both alone.
        for state in rebase-merge rebase-apply MERGE_HEAD BISECT_LOG CHERRY_PICK_HEAD; do
          if [[ -e "$git_dir/$state" ]]; then
            printf '%s: an operation is in flight, skipped\n' "$repo"
            return 0
          fi
        done

        # A stale remote-tracking ref reads as "still alive", which keeps a
        # branch that should go. A failed fetch is therefore conservative, not
        # dangerous, so an offline run simply does less.
        timeout 30 git fetch --prune --quiet 2>/dev/null || true

        if ! read -r trunk trunk_ref < <(trunk_of); then
          printf '%s: no trunk branch to compare against, skipped\n' "$repo" >&2
          return 0
        fi

        tidy_branches "$repo" "$trunk" "$trunk_ref"
        tidy_stashes "$repo"
      }

      for root in "''${roots[@]}"; do
        [[ -d "$root" ]] || continue
        while read -r git_dir; do
          ( tidy_repo "$(dirname "$git_dir")" ) || true
        done < <(find "$root" -maxdepth ${toString cfg.depth} -name .git -type d -prune 2>/dev/null)
      done
    '';
  };
in
{
  options.theorem.home.shell.git-tidy = {
    enable = lib.mkEnableOption "scheduled cleanup of landed branches and orphaned autostashes";

    roots = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "${config.home.homeDirectory}/Projects" ];
      defaultText = lib.literalExpression ''[ "''${config.home.homeDirectory}/Projects" ]'';
      description = ''
        Directories to walk for git repositories. A path may be a repository
        itself or a directory of them.
      '';
    };

    depth = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = ''
        How deep below each root to look for a `.git` directory. Deep enough
        for a workspace of repositories, shallow enough that the walk stays
        cheap.
      '';
    };

    stashAge = lib.mkOption {
      type = lib.types.ints.positive;
      default = 14;
      description = ''
        Days an `autostash` entry must survive before it is dropped. Only
        entries git wrote itself during a rebase are eligible; a stash with a
        message the operator chose is never dropped.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ gitTidy ];

    systemd.user.services.git-tidy = {
      Unit.Description = "Delete landed branches and orphaned autostashes from tended repositories";

      Service = {
        Type = "oneshot";
        ExecStart = "${gitTidy}/bin/git-tidy";
      };
    };

    systemd.user.timers.git-tidy = {
      Unit.Description = "Run the git tidying rite daily";

      Timer = {
        OnBootSec = "5min";
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30min";
        Unit = "git-tidy.service";
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}
