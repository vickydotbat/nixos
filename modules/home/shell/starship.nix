{
  config,
  lib,
  ...
}:
# FIXME: Check for opinionated settings. Set good defaults and derived configuration and then fold the rest into vicky's user.
let
  cfg = config.theorem.home.shell.starship;
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

  config = lib.mkIf cfg.enable {

    programs.starship = {
      enable = true;
      enableBashIntegration = cfg.bashIntegration.enable;
      settings = {
        add_newline = false;
        command_timeout = 1000;
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

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".cache/starship"
      ];
    };
  };
}
