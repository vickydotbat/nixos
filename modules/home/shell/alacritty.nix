{
  config,
  lib,
  ...
}:
# TODO: describe
let
  cfg = config.theorem.home.shell.alacritty;
in
{
  options.theorem.home.shell.alacritty = {
    enable = lib.mkEnableOption "alacritty terminal";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.TERMINFO_DIRS = lib.mkForce (
      lib.concatStringsSep ":" [
        "${config.programs.alacritty.package.terminfo}/share/terminfo"
        "${config.home.profileDirectory}/share/terminfo"
        "/run/current-system/sw/share/terminfo"
      ]
    );

    programs.alacritty = {
      enable = true;
    };
  };
}
