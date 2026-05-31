{ config, lib, ... }:

let
  cfg = config.vicky.nixos.virtualisation.podman;
in
{
  options.vicky.nixos.virtualisation.podman.enable = lib.mkEnableOption "Podman virtualisation stack";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;

      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
