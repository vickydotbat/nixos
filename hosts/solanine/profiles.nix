{
  theorem.nixos = {
    base = {
      boot.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      packages.enable = true;
      persistence.enable = true;
      ssh.enable = true;
      users.enable = true;
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
}
