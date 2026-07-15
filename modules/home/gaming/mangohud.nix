{
  config,
  lib,
  ...
}:
# Neverwinter Nights keeps old path expectations alive on a modern Home profile.
# This module writes the alias files, links tool-specific data directories, and
# persists game state only when the user has selected Home persistence.
let
  cfg = config.theorem.home.gaming.mangohud;
in
{
  options.theorem.home.gaming.mangohud = {
    enable = lib.mkEnableOption "MangoHud";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Additional MangoHud settings merged over the reusable defaults.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.mangohud = {
        enable = true;
        settings = cfg.settings;
      };
    })
  ];
}
