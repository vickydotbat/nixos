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
        Apply low-risk systemd hardening to the Bluetooth service. BlueZ is a
        hardware-facing daemon, so this deliberately avoids broad syscall,
        kernel-module, and process-visibility restrictions that can break
        adapters during pairing, suspend/resume, or reconnect.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = lib.mkDefault false;
    };

    systemd.services.bluetooth.serviceConfig = lib.mkIf cfg.hardenService {
      # Keep this conservative. Bluetooth hardware paths need room for udev,
      # firmware, D-Bus, and adapter-specific reconnect behavior.
      ProtectKernelTunables = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      ProtectControlGroups = lib.mkDefault true;
      SystemCallArchitectures = "native";
    };

  };
}
