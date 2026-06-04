{ config, lib, ... }:

# Bluetooth is an explicit desktop hardware profile. Service hardening stays
# conservative because pairing, firmware, headset reconnect, and suspend/resume
# failures often appear only on real adapters after the build succeeds.
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
      /*
        NOTE: The recent configuration change here did not stop random bluetooth disconnections.

        Further investigation necessary whether the removed risky entries were actually the problem. A hardened default should be used here always, but possibly for Solanine itself these risky features can be disabled.

        Refer to best practices for hardening. Some ideas:

        systemd.services = {
              bluetooth.serviceConfig = {
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
        }
      */
    };

  };
}
