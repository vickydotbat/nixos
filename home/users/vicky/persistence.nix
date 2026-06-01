{ config, pkgs, lib, ... }:
let
  username = config.home.username;
  home = config.home.homeDirectory;

  backingDownloads = "/nix/persist/home/${username}/Downloads";
in
{
  home.persistence."/nix/persist" = {
    directories = [
      "Documents"
      "Pictures"
      "Videos"
      # "Downloads" # I use a volatile btrfs instead
      "Projects"
      "Music"
      "Repositories"
      "Templates"
      "Public"
      "Desktop"
      ".local/share/Steam"
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
    Destroy ~/Downloads between reboots, but keep it on disc with CoW disabled
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
}
