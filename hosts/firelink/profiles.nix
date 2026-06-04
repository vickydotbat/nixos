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
    // lib.optionalAttrs ((user.avatar or null) != null) {
      avatar = user.avatar;
    }
    // lib.optionalAttrs (user.passwordHashSecret != null) {
      passwordHashFile = "/run/secrets-for-users/${user.passwordHashSecret}";
    };
in
{
  theorem.nixos = {
    base = {
      boot = {
        enable = true;
        loader = "systemd-boot";
      };
      locale = {
        enable = true;
        timeZone = "Europe/Rome";
        defaultLocale = "it_IT.UTF-8";
        supportedLocales = [
          "it_IT.UTF-8/UTF-8"
          "en_GB.UTF-8/UTF-8"
        ];
      };
      networking.enable = true;
      nix = {
        enable = true;
        unfreePackageNames = [
          "corefonts"
          "vista-fonts"
        ];
      };
      packages.enable = true;
      persistence.enable = true;
      users = {
        enable = true;
        accounts = lib.mapAttrs mkAccount selectedUsers;
      };
    };

    desktop = {
      audio.enable = true;
      bluetooth = {
        enable = true;
        hardenService = true;
      };
      plasma.enable = true;
      appimage.enable = true;
      graphics.enable = true;
      flatpak.enable = true;
      jailwolf.enable = false;
    };

    security = {
      firejail.enable = false;
      hardening.enable = true;
      polkit.enable = true;
      sudo.enable = true;
      diagnostics.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    nvme-cli
    smartmontools
  ];

  console.keyMap = "it2";
  services.xserver.xkb.layout = "it";
}
