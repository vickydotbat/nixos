{
  lib,
  ...
}:
let
  diskDevice = "/dev/disk/by-id/CHANGE-ME-firelink-system-disk";
  btrfsCompression = "zstd:1";
  btrfsMountOptions = [
    "compress=${btrfsCompression}"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault diskDevice;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
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

        cryptroot = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings = {
              allowDiscards = true;
              bypassWorkqueues = true;
            };
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
                  mountpoint = "/nix/persist";
                  mountOptions = btrfsMountOptions;
                };

                "@swap" = {
                  mountpoint = "/.swapvol";
                  mountOptions = [ "noatime" ];
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
  };

  theorem.nixos.base.persistence = {
    storage = {
      manageFileSystems = false;
      device = "/dev/mapper/cryptroot";
      inherit btrfsCompression;
    };

    root = {
      btrfsSubvolume = "@root";
      btrfsBlankSubvolume = "@root-blank";
      btrfsTopLevelSubvolume = "/";
    };
  };

  fileSystems."/nix".neededForBoot = true;
  fileSystems."/nix/persist".neededForBoot = true;
}
