{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.kitty;
in
{
  options.theorem.home.shell.kitty = {
    enable = lib.mkEnableOption "kitty terminal";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.TERMINFO_DIRS = lib.mkForce (
      lib.concatStringsSep ":" [
        "${config.programs.kitty.package.terminfo}/share/terminfo"
        "${config.home.profileDirectory}/share/terminfo"
        "/run/current-system/sw/share/terminfo"
      ]
    );

    programs.kitty = {
      enable = true;

      font = {
        name = "Hack Nerd Font";
        size = 11;
        package = pkgs.nerd-fonts.hack;
      };
    };
  };
}
