{
  config,
  lib,
  options,
  ...
}:
# Starship owns the prompt signal, not shell behavior. The module keeps a small
# Bash-integrated prompt that exposes repository and Nix shell state without
# burying repair commands under ornament.
let
  cfg = config.theorem.home.shell.starship;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.shell.starship = {
    enable = lib.mkEnableOption "Starship prompt";

    bashIntegration.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.shell.shell.enable or true;
      defaultText = lib.literalExpression "theorem.home.shell.shell.enable";
      description = "Enable Starship integration for the repository's Bash shell theorem.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.starship = {
        enable = true;
        enableBashIntegration = cfg.bashIntegration.enable;
        settings = {
          add_newline = false;
          # 1s is not enough for `git status` in /nix/nixos while something
          # disk-heavy (Steam download, Wine boot) is running.
          command_timeout = 2500;
          directory = {
            truncation_length = 4;
            truncate_to_repo = false;
          };
          git_status = {
            ahead = "ahead ";
            behind = "behind ";
            conflicted = "conflicts ";
            deleted = "deleted ";
            diverged = "diverged ";
            modified = "modified ";
            renamed = "renamed ";
            staged = "staged ";
            stashed = "stashed ";
            untracked = "untracked ";
          };
          nix_shell = {
            format = "via [$symbol$state( \\($name\\))]($style) ";
            symbol = "nix ";
          };
        };
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              ".cache/starship"
            ];
          };
    })
  ];
}
