{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "vickydotbat";
        email = "vickydotbat@tutamail.com";
      };

      init.defaultBranch = "main";
      /*
        - only pull if fast-forward is possible, i.e. there is no divergent history
        - this is to protect against mistakes such as pulling after having rebased/amended/... locally
        - see:
          - https://git-scm.com/docs/git-config#Documentation/git-config.txt-pullff
          - https://git-scm.com/docs/git-pull#Documentation/git-pull.txt---ff-only
        - for a pull with rebase, use `yoink`, see above
      */
      pull.ff = "only";

      # automatically stash-and-unstash changes when rebasing (including when pulling)
      rebase.autoStash = true;

      /*
        - this advice is given on pulling with diverging branches, which is expected
        - just do `git yoink` to explicitly rebase on pull
      */
      advice.diverging = false;

      # automatically set remote when pushing a branch that has no upstream branch yet
      push.autoSetupRemote = true;

      diff = {
        algorithm = "histogram";
        colorMoved = "plain"; # color moved lines differently, see https://git-scm.com/docs/git-diff#Documentation/git-diff.txt-code--color-movedltmodegtcode
        mnmonicPrefix = true; # prefix diff header with short source of file instead of only a/b
      };

      /*
        Uses three-way conflict display that shows the parent and the two changed variants of each
        conflict.

        There's also `zdiff3` which prunes equal lines from the conflict, but I don't use that because
        it can lead to ambiguities. I prefer being able to unambiguously see the entire conflict and
        accept having a bigger conflict area.

        See:
        - https://stackoverflow.com/q/27417656
        - https://github.com/git/git/commit/4496526f80b3e4952036550b279eff8d1babd60a
      */
      merge.conflictStyle = "diff3";

      fetch = {
        all = true; # fetch --all by default

        # prune remote-tracking branches and tags when fetching
        prune = true;
        pruneTags = true;
      };

      column.ui = "auto"; # show lists in columns when outputting to the terminal
      branch.sort = "-committerdate"; # sorts branches by most recent
      tag.sort = "version:refname"; # treat numbers as version numbers when sorting tags

      core = {
        # speed up git in big repos, see `git help status`
        untrackedCache = true;
        fsmonitor = true;
      };

      # config signing manually, home-manager doesn't support SSH signing
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519";
      commit.gpgsign = true; # enable signing by default

    };
  };
}
