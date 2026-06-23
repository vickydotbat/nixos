{
  lib,
  ...
}:
let
  diskDevice = "/dev/disk/by-id/CHANGE-ME-saturnine-system-disk";
  btrfsCompression = "zstd:1";
  btrfsMountOptions = [
    "compress=${btrfsCompression}"
    "noatime"
  ];
in
{
  # Saturnine has two internal drives, but only the main encrypted system disk is
  # declared here. Do not add the secondary disk until installation has recorded
  # stable `/dev/disk/by-id/` paths and the persistence split has been tested on
  # disposable media; a guessed device name is a disk-wipe footgun.
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
