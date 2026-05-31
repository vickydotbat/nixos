{ config, lib, ... }:

let
  cfg = config.vicky.nixos.base.networking;
in
{
  options.vicky.nixos.base.networking.enable = lib.mkEnableOption "base networking configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
