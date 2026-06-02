{ config, lib, ... }:

let
  cfg = config.theorem.nixos.security.polkit;
in
{
  options.theorem.nixos.security.polkit.enable = lib.mkEnableOption "Polkit authorization support";

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
  };
}
