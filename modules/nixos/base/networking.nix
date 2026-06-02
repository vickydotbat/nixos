{ config, lib, ... }:

let
  cfg = config.theorem.nixos.base.networking;
in
{
  options.theorem.nixos.base.networking.enable = lib.mkEnableOption "base networking configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
