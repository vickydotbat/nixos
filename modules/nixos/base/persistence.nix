{
  config,
  lib,
  ...
}:
# TODO: There is no distinction between the btrfs-with-snapshot technique and the current TMPFS technique. Also, many other modules derived from persistance assume, in a way that is not reproducible, that we always use the TMPFS technique. TMPFS has different requirements, such as needing to persist /tmp so that it doesn't go to ram (meanwhile BTRFS would be the reverse: wanting /tmp ON ram). Analysis and refactor needed.
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
