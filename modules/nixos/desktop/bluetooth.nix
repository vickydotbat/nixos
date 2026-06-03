{ config, lib, ... }:

let
  cfg = config.theorem.nixos.desktop.bluetooth;
in
{
  options.theorem.nixos.desktop.bluetooth.enable = lib.mkEnableOption "desktop Bluetooth support";

  config = lib.mkIf cfg.enable {
    # TODO: Add hardened defaults. It should never enable by itself. User input always required. By default, make the system undiscoverable: it will just be used to connect to other devices.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # TODO: Potentially use these as hardening defaults. Evaluate and confirm, use lib.mkDefault for things that can be safely overriden.
    systemd.services.bluetooth.serviceConfig = {
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
