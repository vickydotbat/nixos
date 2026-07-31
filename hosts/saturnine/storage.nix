{
  lib,
  ...
}:
let
  # Both paths were read from the machine with `ls -l /dev/disk/by-id/`. Note
  # that the kernel names are the reverse of what the sizes suggest: the 1 TB
  # Crucial is `nvme0n1` and the 512 GB Samsung is `nvme1n1`. By-id paths are
  # used precisely so that ordering can never matter.
  #
  # The 512 GB disk carries the boot partition and the impermanent system: the
  # root subvolume that is rolled back on every boot, the Nix store, and swap.
  # The 1 TB disk carries `/nix/persist`, which is the only state that survives
  # a reboot, so bulk home data lands on the large drive by construction.
  systemDiskDevice = "/dev/disk/by-id/nvme-SAMSUNG_MZVLQ512HBLU-00B00_S6F5NJ0R331579";
  persistDiskDevice = "/dev/disk/by-id/nvme-CT1000T500SSD8_233543ACCDA1";

  btrfsCompression = "zstd:1";
  btrfsMountOptions = [
    "compress=${btrfsCompression}"
    "noatime"
  ];

  luksSettings = {
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  # Read by `disko` at format time only; disko passes `device` and `settings` to
  # `boot.initrd.luks.devices`, never `passwordFile`, so nothing about this path
  # reaches the built system. It exists in the installer's tmpfs and dies with
  # it.
  #
  # Both volumes are formatted from the same file, which is what makes the
  # single boot prompt reliable: systemd-ask-password caches the first answer
  # and reuses it, and a byte-identical passphrase is required for that to work.
  # Typing it twice by hand would not guarantee this.
  #
  # Populate during installation from the encrypted host file:
  #   sops -d --extract '["luks"]["passphrase"]' secrets/hosts-saturnine.yaml \
  #     > /tmp/luks-passphrase
  luksPasswordFile = "/tmp/luks-passphrase";
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault systemDiskDevice;
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
            passwordFile = luksPasswordFile;
            settings = luksSettings;
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

  # `/nix/persist` is `neededForBoot`, so this volume is unlocked in the initrd
  # alongside the system disk. Give it the SAME passphrase: systemd-ask-password
  # caches the first answer and reuses it for the second volume, so boot asks
  # once. Different passphrases mean two prompts, which is inconvenient but not
  # broken.
  #
  # The tradeoff of putting persistent state on its own disk: if this drive
  # fails the machine will not boot, rather than booting without its data.
  disko.devices.disk.persist = {
    type = "disk";
    device = lib.mkDefault persistDiskDevice;
    content = {
      type = "gpt";
      partitions.cryptpersist = {
        size = "100%";
        content = {
          type = "luks";
          name = "cryptpersist";
          passwordFile = luksPasswordFile;
          settings = luksSettings;
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
              "-L"
              "PERSIST"
            ];
            subvolumes."@persist" = {
              mountpoint = "/nix/persist";
              mountOptions = btrfsMountOptions;
            };
          };
        };
      };
    };
  };

  theorem.nixos.base.persistence = {
    storage = {
      manageFileSystems = false;
      # Only the rollback rite reads this: it is the device holding `@root` and
      # `@root-blank`, not the device holding persisted state.
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
