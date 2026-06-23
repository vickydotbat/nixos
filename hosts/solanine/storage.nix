{
  lib,
  ...
}:
let
  diskDevice = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B73839907E9";
  btrfsCompression = "zstd:1";
  btrfsMountOptions = [
    "compress=${btrfsCompression}"
    "noatime"
  ];
in
{
  # This disk setup is not final. It is post-repositioning / on btrfs.
  # FIXME if you ever reinstall Solanine.
  disko.devices._config = {
    type = "disk";
    device = lib.mkDefault diskDevice;
    content = {
      type = "gpt";
      partitions = {
        EFI = {
          priority = 1;
          name = "EFI";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
              "defaults"
            ];
          };
        };

        ROOT = {
          name = "ROOT";
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "ROOT"
            ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = btrfsMountOptions;
              };

              "@root-blank" = { };

              "@nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsMountOptions;
              };

              "@persist" = {
                mountpoint = "/persist";
                mountOptions = btrfsMountOptions;
              };

              "@swap" = {
                mountpoint = "/swap";
                mountOptions = [
                  "noatime"
                  "nodatacow"
                ];
                swap.swapfile = {
                  size = "16G";
                  priority = 0;
                };
              };
            };
          };
        };
      };
    };
  };

  theorem.nixos.base.persistence = {
    storage = {
      manageFileSystems = false;
      fsType = "btrfs";
      device = "/dev/disk/by-label/ROOT";
      inherit btrfsCompression;
    };

    root = {
      mode = "btrfs";
      btrfsSubvolume = "@root";
      btrfsBlankSubvolume = "@root-blank";
      btrfsTopLevelSubvolume = "/";
    };

    boot.device = "/dev/disk/by-label/EFI";
  };

  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
}
