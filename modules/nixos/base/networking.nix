{ config, lib, pkgs, ... }:

let
  cfg = config.vicky.nixos.base.networking;

  normalizeSystemWifiProfiles = pkgs.writeShellApplication {
    name = "normalize-system-wifi-profiles";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.networkmanager
      pkgs.systemd
    ];
    text = ''
      set -eu
      shopt -s nullglob

      connections_dir=/etc/NetworkManager/system-connections
      changed=0

      for profile in "$connections_dir"/*.nmconnection; do
        if ! grep -qE '^\[wifi\]$|^type=wifi$' "$profile"; then
          continue
        fi

        if grep -qE '^permissions=' "$profile"; then
          sed -i '/^permissions=/d' "$profile"
          changed=1
        fi

        if grep -qE '^psk=' "$profile"; then
          if grep -qE '^psk-flags=' "$profile"; then
            sed -i 's/^psk-flags=.*/psk-flags=0/' "$profile"
          else
            sed -i '/^psk=/a psk-flags=0' "$profile"
          fi
          changed=1
        elif grep -qE '^psk-flags=([^0]|..*)' "$profile"; then
          echo "Wi-Fi profile $profile still uses a user secret agent; save its password as a system connection once." >&2
        fi

        chown root:root "$profile"
        chmod 0600 "$profile"
      done

      if (( changed )) && systemctl -q is-active NetworkManager.service; then
        nmcli connection reload
      fi
    '';
  };
in
{
  options.vicky.nixos.base.networking.enable = lib.mkEnableOption "base networking configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    systemd.services.normalize-system-wifi-profiles = {
      description = "Keep NetworkManager Wi-Fi profiles system-wide";
      before = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.systemd ];
      serviceConfig.Type = "oneshot";
      script = "${normalizeSystemWifiProfiles}/bin/normalize-system-wifi-profiles";
    };

    systemd.paths.normalize-system-wifi-profiles = {
      description = "Watch NetworkManager Wi-Fi profile changes";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = "/etc/NetworkManager/system-connections";
        Unit = "normalize-system-wifi-profiles.service";
      };
    };
  };
}
