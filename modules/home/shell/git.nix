{
  config,
  lib,
  options,
  repository,
  pkgs,
  ...
}:
# Git is the history and review layer for the system theorem. The shared module
# owns conservative defaults, repository safe-directory posture, LFS support,
# and SSH commit signing wired to the Home SSH identity.
let
  cfg = config.theorem.home.shell.git;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
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

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist the `tea` Gitea CLI login (`~/.config/tea`) when Home
        persistence is active. Disable to force re-authenticating `tea` on each
        boot; keep enabled so the stored login token survives reboot.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
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

            /*
              Dead-branch cleanup, in two deliberate steps.

              `fetch.prune` above already removes the remote-tracking refs. It
              does not touch the local branches that pointed at them, so a
              long-lived checkout silently accumulates branches whose upstream
              is gone — the forge deleted the remote head when the pull request
              merged, and the local copy stayed behind.

              `git gone` lists them and deletes nothing. `git gone-prune`
              deletes them. Never wire the second one into a timer, an
              activation hook, or a shell startup file: the operator decides
              when history is discarded.

              The deletion uses `-D`, not `-d`, and that is the sharp edge.
              A forge that squash-merges rewrites the commits, so a merged
              branch is never an ancestor of `main` and `-d` refuses all of
              them. `-D` deletes regardless of merge state, which means a
              branch that was pushed, had its remote head deleted, and then
              received new local commits will lose those commits. Read the
              output of `git gone` before running `git gone-prune`; that is
              the whole safety mechanism.

              `gone-prune` skips the checked-out branch, which Git would refuse
              to delete anyway, so the run does not fail on it.
            */
            alias = {
              gone = lib.mkDefault "!git fetch --prune --quiet; git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | awk '$2 == \"[gone]\" { print $1 }'";
              gone-prune = lib.mkDefault "!git gone | grep -vxF \"$(git branch --show-current)\" | xargs -r git branch -D";
            };

            # Trust only this declared shared theorem repository. Do not use
            # `safe.directory = "*"`, which would silence Git's ownership check
            # for every checkout Vicky opens.
            safe.directory = repository.path;

            core = {
              # speed up git in big repos, see `git help status`
              untrackedCache = lib.mkDefault true;

              # `core.fsmonitor` stays off. Its daemon costs a multi-second
              # cold scan on the first Git call in a repository after every
              # boot, which stalls the shell prompt, and its socket under
              # `.git` makes Nix refuse to evaluate a flake at that path.
              # Repositories large enough to need it can opt in themselves.
            };
          }
          (lib.mkIf cfg.sshSigning.enable {
            user.signingkey = cfg.sshSigning.keyPath;
            gpg.format = "ssh";
            commit.gpgsign = true;
          })
        ];
      };

      home.packages = with pkgs; [
        tea
        github-cli
      ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".config/tea"
        ];
      };
    })
  ];
}
