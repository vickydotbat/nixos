{ config, lib, ... }:

let
  cfg = config.theorem.nixos.desktop.bluetooth;
in
{
  options.theorem.nixos.desktop.bluetooth = {
    enable = lib.mkEnableOption "desktop Bluetooth support";

    hardenService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apply a narrow systemd sandbox to the Bluetooth service. Disable only
        when a specific adapter or pairing workflow proves which guard blocks
        it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = lib.mkDefault false;
    };

    systemd.services.bluetooth.serviceConfig = lib.mkIf cfg.hardenService {
      ProtectKernelTunables = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectHostname = true;
      ProtectControlGroups = true;
      ProtectProc = "invisible";
      SystemCallFilter = [
        "~@obsolete"
        "~@cpu-emulation"
        "~@swap"
        "~@reboot"
        "~@mount"
      ];
      SystemCallArchitectures = "native";
    };

  };
}
