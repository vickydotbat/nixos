{
  config,
  lib,
  repository,
  ...
}:
# Git is the history and review layer for the system theorem. The shared module
# owns conservative defaults, repository safe-directory posture, LFS support,
# and SSH commit signing wired to the Home SSH identity.
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
      # LFS support is cheap insurance for repositories that already use it;
      # missing filters can corrupt large-file workflows before repair begins.
      lfs.enable = lib.mkForce true;

      settings = lib.mkMerge [
        {
          init.defaultBranch = lib.mkDefault "main";
          /*
            - only pull if fast-forward is possible, i.e. there is no divergent history
            - this is to protect against mistakes such as pulling after having rebased/amended/... locally
            - see:
              - https://git-scm.com/docs/git-config#Documentation/git-config.txt-pullff
              - https://git-scm.com/docs/git-pull#Documentation/git-pull.txt---ff-only
            - for a pull with rebase, use `yoink`, see above
          */
          pull.ff = lib.mkDefault "only";

          # automatically stash-and-unstash changes when rebasing (including when pulling)
          rebase.autoStash = lib.mkDefault true;

          /*
            - this advice is given on pulling with diverging branches, which is expected
            - just do `git yoink` to explicitly rebase on pull
          */
          advice.diverging = lib.mkDefault false;

          # Keep the first publish explicit. Vicky manages repositories with
          # multiple remotes; guessing the upstream is convenient until it
          # binds a branch to the wrong forge.
          push.autoSetupRemote = lib.mkDefault false;
          push.default = lib.mkDefault "simple";
          push.followTags = lib.mkDefault true;

          diff = {
            algorithm = lib.mkDefault "histogram";
            colorMoved = lib.mkDefault "plain"; # color moved lines differently, see https://git-scm.com/docs/git-diff#Documentation/git-diff.txt-code--color-movedltmodegtcode
            mnemonicPrefix = lib.mkDefault true; # prefix diff header with short source of file instead of only a/b
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
          merge.conflictStyle = lib.mkDefault "diff3";

          fetch = {
            all = lib.mkDefault true; # fetch --all by default

            # prune remote-tracking branches and tags when fetching
            prune = lib.mkDefault true;
            pruneTags = lib.mkDefault true;
            showForcedUpdates = lib.mkDefault true;
          };

          column.ui = lib.mkDefault "auto"; # show lists in columns when outputting to the terminal
          branch.sort = lib.mkDefault "-committerdate"; # sorts branches by most recent
          tag.sort = lib.mkDefault "version:refname"; # treat numbers as version numbers when sorting tags

          # Trust only this declared shared theorem repository. Do not use
          # `safe.directory = "*"`, which would silence Git's ownership check
          # for every checkout Vicky opens.
          safe.directory = repository.path;

          core = {
            # speed up git in big repos, see `git help status`
            untrackedCache = lib.mkDefault true;
            fsmonitor = lib.mkDefault true;
          };
        }
        (lib.mkIf cfg.sshSigning.enable {
          user.signingkey = cfg.sshSigning.keyPath;
          gpg.format = "ssh";
          commit.gpgsign = true;
        })
      ];
    };
  };
}
