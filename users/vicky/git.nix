{
  programs.git = {
    settings.user = {
      name = "vickydotbat";
      email = "vickydotbat@tutamail.com";
    };

    extraConfig = {
      pull = {
        ff = "only";
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
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
  };
}
