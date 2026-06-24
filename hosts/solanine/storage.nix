{
  theorem.nixos.base.persistence = {
    storage = {
      device = "/dev/disk/by-label/ROOT";
      btrfsCompression = "zstd:1";
    };

    root = {
      btrfsSubvolume = "@root";
      btrfsBlankSubvolume = "@root-blank";
      btrfsTopLevelSubvolume = "/";
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
      priority = 10; # TODO: Default this with zram
    }
  ];
}
