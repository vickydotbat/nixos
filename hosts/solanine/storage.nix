{
  theorem.nixos.base.persistence = {
    storage = {
      fsType = "btrfs";
      device = "/dev/disk/by-label/ROOT";
      btrfsCompression = "zstd:1";
    };

    root = {
      mode = "tmpfs";
      tmpfsSize = "25%";
    };

    boot.device = "/dev/disk/by-label/EFI";
  };

  # Temporary recovery mount for state migration. This is a Solanine exception,
  # not part of the reusable persistence theorem.
  fileSystems."/homeold" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "nodatacow"
    ];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024;
    }
  ];

  services.fstrim.enable = true;
}
