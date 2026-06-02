{
  config,
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.persistence;
  systemPersistenceEnabled = (osConfig.theorem.nixos.base.persistence.enable or false);

  # Default mechanism, kept in the reusable module; home/ may override it.
  username = config.home.username;
  home = config.home.homeDirectory;

  backingDownloads = "/nix/persist/home/${username}/Downloads";
in
{
  options.theorem.home.base.persistence.enable = lib.mkOption {
    type = lib.types.bool;
    default = systemPersistenceEnabled;
    defaultText = lib.literalExpression "osConfig.theorem.nixos.base.persistence.enable or false";
    description = ''
      Enable Home Manager persistence. Defaults to the system persistence
      theorem so user bind mounts are only declared when the persistence
      substrate exists.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.persistence."/nix/persist" = {
      directories = [
        # XDG Directories
        "Documents"
        "Pictures"
        "Videos"
        # "Downloads" # Volatile btrfs instead -- see below
        "Projects"
        "Music"
        "Templates"
        "Public"
        "Desktop"

        # My custom directories
        "Repositories"
        "Backups"
        "Games"
        "Applications"

        # Nix cache -- must keep when using tmpfs
        ".cache/nix"

        # systemd Timers
        ".local/share/systemd/timers"
      ];

      files = [
        {
          file = ".ssh/known_hosts";
          parentDirectory.mode = "0700";
        }
      ];
    };

    /*
      Destroy ~/Downloads between reboots
      but keep it on disc with CoW disabled
    */
    home.activation.linkVolatileDownloads = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf "$HOME/Downloads"
      mkdir -p "${backingDownloads}"
      ln -sfn "${backingDownloads}" "$HOME/Downloads"
    '';

    systemd.user.services.volatile-downloads = {
      Unit = {
        Description = "Prepare volatile disk-backed Downloads directory";
      };

      Service = {
        Type = "oneshot";

        ExecStart = pkgs.writeShellScript "volatile-downloads" ''
          set -eu

          backing="${backingDownloads}"

          # Ensure the parent exists.
          mkdir -p "$(dirname "$backing")"

          # Wipe previous contents, but keep the directory itself.
          rm -rf "$backing"
          mkdir -p "$backing"

          chmod 0755 "$backing"

          # Set Btrfs NoCoW. This only affects new files created afterward.
          ${pkgs.e2fsprogs}/bin/chattr +C "$backing" || true

          # Ensure ~/Downloads points at the disk-backed volatile directory.
          rm -rf "${home}/Downloads"
          ln -sfn "$backing" "${home}/Downloads"
        '';
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
