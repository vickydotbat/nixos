{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.desktop.blender;

  # Default mechanism, kept in the reusable module; home/ may override it.
  blender = pkgs.blender;
  blenderConfigVersion = lib.versions.majorMinor blender.version;
in
{
  options.theorem.home.desktop.blender.enable = lib.mkEnableOption "Blender";

  config = lib.mkIf cfg.enable {
    home.packages = [
      blender
    ];

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        "Blender"
        ".config/blender/${blenderConfigVersion}"
      ];
    };
  };
}
