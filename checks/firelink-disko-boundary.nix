{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  config = inputs.self.nixosConfigurations.firelink.config;
  disk = config.disko.devices.disk.main;
  partitions = disk.content.partitions;
  cryptroot = partitions.cryptroot.content;
  btrfs = cryptroot.content;
  subvolumes = btrfs.subvolumes;
  swapDevice = builtins.head config.swapDevices;
in
assert config.networking.hostName == "firelink";
assert disk.device == "/dev/disk/by-id/CHANGE-ME-firelink-system-disk";
assert partitions.ESP.size == "1G";
assert partitions.ESP.content.mountpoint == "/boot";
assert cryptroot.type == "luks";
assert cryptroot.name == "cryptroot";
assert cryptroot.settings.allowDiscards;
assert cryptroot.settings.bypassWorkqueues;
assert subvolumes."@root".mountpoint == "/";
assert subvolumes."@root-blank".mountpoint == null;
assert subvolumes."@nix".mountpoint == "/nix";
assert subvolumes."@persist".mountpoint == "/nix/persist";
assert subvolumes."@swap".mountpoint == "/.swapvol";
assert subvolumes."@swap".swap.swapfile.size == "16G";
assert swapDevice.device == "/.swapvol/swapfile";
assert swapDevice.priority == 0;
assert config.services.xserver.xkb.layout == "it";
assert config.console.keyMap == "it2";
assert lib.elem "kvm-intel" config.boot.kernelModules;
assert config.theorem.nixos.base.persistence.storage.manageFileSystems == false;
assert config.theorem.nixos.base.persistence.root.mode == "btrfs";
assert config.boot.initrd.systemd.services.rollback-root.before == [ "sysroot.mount" ];
assert config.fileSystems."/nix".neededForBoot;
assert config.fileSystems."/nix/persist".neededForBoot;
pkgs.runCommand "firelink-disko-boundary" { } ''
  touch "$out"
''
