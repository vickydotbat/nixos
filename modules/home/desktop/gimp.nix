{
  config,
  lib,
  pkgs,
  ...
}:
# GIMP is kept as a reusable graphics mechanism with a package override. Plugin
# heavy builds and artist-specific workflow belong in user modules so the shared
# desktop layer does not inherit one operator's studio.
let
  cfg = config.theorem.home.desktop.gimp;
in
{
  options.theorem.home.desktop.gimp = {
    enable = lib.mkEnableOption "GIMP";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.gimp3;
      defaultText = lib.literalExpression "pkgs.gimp3";
      description = ''
        GIMP package installed for this user. Plugin-bearing custom builds are
        user workflow and should be selected in user modules.
      '';
    };

    persistConfig = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.base.persistence.enable;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist GIMP user configuration when Home persistence is active.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    home.persistence."/nix/persist" = lib.mkIf cfg.persistConfig {
      directories = [
        ".config/GIMP"
      ];
    };
  };
}
