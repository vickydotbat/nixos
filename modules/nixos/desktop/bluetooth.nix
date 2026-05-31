{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.bluetooth;
in
{
  options.vicky.nixos.desktop.bluetooth.enable = lib.mkEnableOption "desktop Bluetooth support";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
