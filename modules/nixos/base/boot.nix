{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.theorem.nixos.base.boot;
in
{
  options.theorem.nixos.base.boot = {
    enable = lib.mkEnableOption "base boot configuration"; # FIXME: Boot modules are always necessary. This should at least be enabled by default, especially because it sets the default kernel.

    loader = lib.mkOption {
      type = lib.types.enum [
        "systemd-boot"
      ];
      default = "systemd-boot";
      description = ''
        Boot loader family for this host. Only `systemd-boot` is forged here
        today; add GRUB or Lanzaboote as separate, named mechanisms when a host
        actually needs them.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    boot.loader.systemd-boot = lib.mkIf (cfg.loader == "systemd-boot") {
      enable = true;
      configurationLimit = lib.mkDefault 10;
    };

    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  };
}
