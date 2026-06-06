{
  programs.git = {
    settings.user = {
      name = "vickydotbat";
      email = "vickydotbat@tutamail.com";
    };

    extraConfig = {
      pull = {
        # Make `git pull` rebase instead of merge when fast-forward is not possible.
        rebase = true;

        # Optional: only allow fast-forward when not rebasing.
        # I would usually omit this if pull.rebase=true is your main policy.
        # ff = "only";
      };

      rebase = {
        # Temporarily stash dirty worktree changes before rebasing, then reapply.
        autoStash = true;

        # Better when rebasing branches with merge commits.
        # Safe to omit if you mostly use linear feature branches.
        rebaseMerges = true;
      };

      branch = {
        # New tracking branches default to pull --rebase behavior.
        autosetuprebase = "always";
      };
    };
  };
}
