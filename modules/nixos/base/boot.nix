{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.vicky.nixos.base.boot;
in
{
  options.vicky.nixos.base.boot.enable = lib.mkEnableOption "base boot configuration";

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 15;
    };

    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_6_12;
  };
}
