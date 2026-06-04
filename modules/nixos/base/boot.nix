{
  config,
  lib,
  pkgs,
  ...
}:
# Base boot substrate for ordinary NixOS hosts in this flake. It owns the
# default kernel family and bootloader retention, while sharper boot-chain work
# such as Lanzaboote or alternate loaders should arrive as named mechanisms.
let
  cfg = config.theorem.nixos.base.boot;
in
{
  options.theorem.nixos.base.boot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the base boot profile. This defaults on because the profile owns
        bootloader defaults and the repository's kernel selection; hosts should
        disable it only when another boot mechanism provides both explicitly.
      '';
    };

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
