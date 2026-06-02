{
  config,
  lib,
  ...
}:

let
  cfg = config.theorem.nixos.base.persistence;
in
{
  options.theorem.nixos.base.persistence.enable =
    lib.mkEnableOption "system persistence for impermanence";

  config = lib.mkIf cfg.enable {
    fileSystems."/nix".neededForBoot = true;

    boot.tmp.cleanOnBoot = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = [
        {
          directory = "/tmp"; # Cleaned on boot.
          mode = "1777";
        }
        { directory = "/etc/NetworkManager/system-connections"; }
        { directory = "/var/lib/nixos"; }
        { directory = "/var/lib/bluetooth"; }
        { directory = "/var/log"; }
        { directory = "/var/lib/systemd/timers"; }
        { directory = "/var/lib/systemd/coredump"; }
        { directory = "/var/tmp"; }
      ];

      files = [
        "/etc/machine-id"
      ];
    };

    services.journald.extraConfig = ''
      SystemMaxUse=512M
      SystemKeepFree=1G
      RuntimeMaxUse=128M
      MaxFileSec=1week
    '';
  };
}
