{ config, lib, ... }:

let
  cfg = config.theorem.nixos.gaming.core;
in
{
  options.theorem.nixos.gaming.core.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.theorem.nixos.gaming.steam.enable;
    defaultText = lib.literalExpression "theorem.nixos.gaming.steam.enable";
    description = ''
      Enable shared gaming substrate used by game profiles. Steam currently
      needs GameMode, and future gaming modules should gather common machinery
      here instead of each carrying its own copy.
    '';
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode.enable = true;
  };
}
