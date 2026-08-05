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

    # Push over SSH even when the remote is an https:// URL. The key is
    # already on every system that gets this profile, since it is the same
    # identity `sshSigning` uses to sign commits, so a fresh machine can push
    # without `gh auth login`, a `tea` token, or a credential helper.
    #
    # `pushInsteadOf`, not `insteadOf`: fetching stays anonymous over https.
    # Rewriting fetches too would make cloning depend on the key being
    # present, and Nix's git fetcher honours these rewrites when it resolves
    # `git+https://` flake inputs.
    #
    # Gitea knows this key as `archvillainette`; the SSH user is still `git`,
    # and `ssh-hosts.nix` pins the host to port 22, so no ssh:// form with an
    # explicit port is needed here.
    url = {
      "git@github.com:".pushInsteadOf = "https://github.com/";
      "git@git.westgate.pw:".pushInsteadOf = "https://git.westgate.pw/";
    };
  };
}
