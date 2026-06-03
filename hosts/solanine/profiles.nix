{
  lib,
  pkgs,
  selectedUsers,
  ...
}:
let
  mkAccount =
    _: user:
    {
      description = user.description;
      uid = user.uid;
      home = user.homeDirectory;
      extraGroups = user.extraGroups;
    }
    // lib.optionalAttrs (user.passwordHashSecret != null) {
      passwordHashFile = "/run/secrets-for-users/${user.passwordHashSecret}";
    };
in
{
  theorem.nixos = {
    base = {
      boot.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      nix.unfreePackageNames = [
        "corefonts"
        "discord"
        "obsidian"
        "spotify"
        "unrar"
        "vista-fonts"
        "vscode"
        "vscode-extension-MS-python-vscode-pylance"
        "vscode-extension-ms-python-python"
        "vscode-extension-ms-vscode-cpptools"
      ];
      packages.enable = true;
      persistence.enable = true;
      ssh.enable = true;
      users = {
        enable = true;
        accounts = lib.mapAttrs mkAccount selectedUsers;
      };
    };

    desktop = {
      bluetooth.enable = true;
      plasma.enable = true;
      appimage.enable = true;
      flatpak.enable = false;
      jailwolf.enable = true;
    };

    gaming = {
      steam.enable = true;
    };

    virtualisation = {
      podman.enable = true;
    };

    security = {
      sudo.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    unrar
    p7zip
    e2fsprogs
    btrfs-progs
    nvme-cli
    smartmontools

    wineWow64Packages.staging
  ];
}
