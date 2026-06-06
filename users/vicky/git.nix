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
      default = "simple";
      autoSetupRemote = false;
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
}
