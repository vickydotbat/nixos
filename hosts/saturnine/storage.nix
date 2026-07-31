{
  lib,
  ...
}:
let
  # Both paths were read from the machine with `ls -l /dev/disk/by-id/`. Note
  # that the kernel names are the reverse of the sizes one might assume: the
  # 1 TB Crucial is `nvme0n1` and the 512 GB Samsung is `nvme1n1`. By-id paths
  # are used precisely so that ordering can never matter.
  diskDevice = "/dev/disk/by-id/nvme-SAMSUNG_MZVLQ512HBLU-00B00_S6F5NJ0R331579";
  dataDiskDevice = "/dev/disk/by-id/nvme-CT1000T500SSD8_233543ACCDA1";

  # The data disk is unlocked from a key file that lives on the already-unlocked
  # system disk, so the machine asks for exactly one passphrase at boot. The key
  # file must therefore never be readable from anywhere but the encrypted root.
  dataKeyFile = "/nix/persist/secrets/luks/data.key";
  dataMapper = "cryptdata";

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

  # Bulk storage: games, media, and anything else too large to belong on the
  # system disk. It is deliberately NOT `neededForBoot`, because its key file
  # only exists once the encrypted root is mounted. Nothing required to reach a
  # login prompt may live here.
  disko.devices.disk.data = {
    type = "disk";
    device = lib.mkDefault dataDiskDevice;
    content = {
      type = "gpt";
      partitions.cryptdata = {
        size = "100%";
        content = {
          type = "luks";
          name = dataMapper;

          # Unlocked by systemd from /etc/crypttab after switch-root, not by the
          # initrd, which cannot read a key file stored inside the encrypted
          # root it has not mounted yet.
          initrdUnlock = false;

          settings = {
            allowDiscards = true;
            bypassWorkqueues = true;
            keyFile = dataKeyFile;
          };

          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "DATA"
            ];
            subvolumes."@data" = {
              mountpoint = "/data";
              mountOptions = btrfsMountOptions ++ [ "nofail" ];
            };
          };
        };
      };
    };
  };

  # systemd unlocks the data disk in the real root, where the key file is
  # readable. `nofail` keeps a missing or failed data disk from blocking boot:
  # a laptop that will not reach a login prompt because a games volume is
  # unhappy is a worse failure than a missing games volume.
  environment.etc.crypttab.text = ''
    ${dataMapper} ${dataDiskDevice}-part1 ${dataKeyFile} luks,discard,nofail
  '';

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
