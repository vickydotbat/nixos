{
  config,
  lib,
  repository,
  ...
}:

let
  cfg = config.theorem.home.shell.git;
in
{
  options.theorem.home.shell.git = {
    enable = lib.mkEnableOption "Git";

    sshSigning = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.theorem.home.base.ssh.enable or false;
        defaultText = lib.literalExpression "theorem.home.base.ssh.enable";
        description = ''
          Sign Git commits with the user's restored SSH identity. This follows
          the Home SSH key rite by default and does not imply that the system
          OpenSSH server is enabled.
        '';
      };

      keyPath = lib.mkOption {
        type = lib.types.str;
        default = "~/.ssh/id_ed25519";
        description = "SSH public/private identity path Git should use for commit signing.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = lib.mkForce true; # NOTE: This should be global for every git installation, and I don't know why it isn't. When LFS isn't installed git can do some serious damage to repos that use it.

      settings = {
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

        safe.directory = repository.path;

        core = {
          # speed up git in big repos, see `git help status`
          untrackedCache = true;
          fsmonitor = true;
        };
      }
      // lib.optionalAttrs cfg.sshSigning.enable {
        user.signingkey = cfg.sshSigning.keyPath;
        gpg.format = "ssh";
        commit.gpgsign = true;
      };
    };
  };
}
