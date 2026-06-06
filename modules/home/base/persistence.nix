{
  config,
  lib,
  options,
  osConfig ? null,
  pkgs,
  ...
}:
# Home Manager persistence baseline for impermanent hosts. It follows the
# system persistence substrate by default, but individual users can opt out when
# their home should stay ephemeral. The volatile Downloads service keeps casual
# downloads boot-scoped while preserving the declared working directories.
let
  cfg = config.theorem.home.base.persistence;
  hasHomePersistence = options.home ? persistence;

  systemPersistenceEnabled =
    if osConfig == null then false else osConfig.theorem.nixos.base.persistence.enable or false;

  username = config.home.username;
  home = config.home.homeDirectory;

  downloadsParent = "/tmp/home/${username}";
  backingDownloads = "${downloadsParent}/Downloads";
in
{
  options.theorem.home.base.persistence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = systemPersistenceEnabled;
      defaultText = lib.literalExpression ''
        if osConfig == null
        then false
        else osConfig.theorem.nixos.base.persistence.enable or false
      '';
      description = ''
        Enable Home Manager persistence. Defaults to the system persistence
        theorem so user bind mounts are only declared when the persistence
        substrate exists.
      '';
    };

    volatileDownloads.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Place `~/Downloads` on boot-scoped `/tmp` storage. Disable this on hosts
        where `/tmp` is memory-backed or where downloads must survive reboot.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || hasHomePersistence;
          message = ''
            theorem.home.base.persistence.enable requires the Home persistence
            option provider. Import the Impermanence Home Manager module through
            the NixOS persistence substrate before enabling this theorem.
          '';
        }
      ];
    }
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf cfg.enable {
        directories = [
          ".local/share/systemd/timers"
          ".local/share/nix"

          # XDG Directories
          "Documents"
          "Pictures"
          "Videos"
          "Projects"
          "Music"
          "Templates"
          "Public"
          "Desktop"

          # Additional global directories
          "Games"
          "Applications"
          "Backups"
          "Repositories"

          # Nix cache -- must keep when using tmpfs home
          # TODO: Disable on btrfs persistence setups. This is only necessary for home on tmpfs.
          ".cache/nix"
        ]
        ++ lib.optionals (!cfg.volatileDownloads.enable) [
          "Downloads"
        ];

        files = [ ];
      };

    })
    (lib.mkIf cfg.enable {
      systemd.user.services.volatile-downloads = lib.mkIf cfg.volatileDownloads.enable {
        Unit = {
          Description = "Prepare boot-scoped Downloads directory";
        };

        Service = {
          Type = "oneshot";

          ExecStart = pkgs.writeShellScript "volatile-downloads" ''
            set -eu

            parent="${downloadsParent}"
            backing="${backingDownloads}"

            # /tmp is disk-backed by system persistence and cleaned on boot.
            mkdir -p /tmp/home
            chmod 1777 /tmp/home

            mkdir -p "$parent"
            chmod 0755 "$parent"
            mkdir -p "$backing"
            chmod 0755 "$backing"

            # Set Btrfs NoCoW. This only affects new files created afterward.
            ${pkgs.e2fsprogs}/bin/chattr +C "$backing" || true

            # Ensure ~/Downloads points at the disk-backed volatile directory.
            # A real directory in the way should fail loudly rather than lose data.
            ln -sfnT "$backing" "${home}/Downloads"
          '';
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ];
}
