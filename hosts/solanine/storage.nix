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
}
