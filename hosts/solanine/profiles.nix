{
  vicky.nixos = {
    base = {
      boot.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix.enable = true;
      packages.enable = true;
      ssh.enable = true;
      users.enable = true;
    };

    desktop = {
      audio.enable = true;
      bluetooth.enable = true;
      graphics.enable = true;
      plasma.enable = true;
      appimage.enable = true;
      flatpak.enable = false;
      jailwolf.enable = true;
    };

    gaming = {
      steam.enable = true;
    };

    virtualisation = {
      nix-ld.enable = true;
      podman.enable = true;
    };

    security = {
      firejail.enable = true;
    };
  };
}
