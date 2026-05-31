{ pkgs, ... }:

{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;
}
