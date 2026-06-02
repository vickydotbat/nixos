{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.desktop.gimp;
in
{
  options.theorem.home.desktop.gimp.enable = lib.mkEnableOption "GIMP";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gimp3-custom
    ];

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".config/GIMP"
      ];
    };
  };
}
