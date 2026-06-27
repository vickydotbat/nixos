{
  programs.git.settings = {
    user = {
      name = "vickydotbat";
      email = "vickydotbat@tutamail.com";
    };

    pull = {
      ff = "only";
    };

    push = {
      # Push the current local branch to a same-named branch on the remote.
      # This avoids accidentally treating origin/main as the push target
      # for feature branches.
      default = "current";

      # On first push of a new branch, automatically set upstream to
      # origin/<current-branch-name>.
      autoSetupRemote = true;

      followTags = true;
    };

    branch = {
      # Only auto-configure tracking when the branch names match.
      # This prevents new feature branches from silently tracking origin/main.
      autoSetupMerge = "simple";
    };

    fetch = {
      prune = true;
      pruneTags = true;
      showForcedUpdates = true;
    };

    merge = {
      conflictStyle = "zdiff3";
    };

    rerere = {
      enabled = true;
    };

    init = {
      defaultBranch = "main";
    };
  };
}
