{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.graphics;
in
{
  options.vicky.nixos.desktop.graphics.enable = lib.mkEnableOption "desktop graphics support";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
