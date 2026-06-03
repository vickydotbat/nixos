{ config, lib, ... }:
# TODO: Rethink this, understand what polkit is good for and where it needs to be enabled.
let
  cfg = config.theorem.nixos.security.polkit;
in
{
  options.theorem.nixos.security.polkit.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.theorem.nixos.desktop.plasma.enable;
    defaultText = lib.literalExpression "theorem.nixos.desktop.plasma.enable";
    description = "Enable Polkit authorization support with the Plasma desktop profile by default.";
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
  };
}
