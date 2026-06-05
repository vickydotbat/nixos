{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  config = inputs.self.nixosConfigurations.saturnine.config;
  disk = config.disko.devices.disk.main;
  partitions = disk.content.partitions;
  cryptroot = partitions.cryptroot.content;
  btrfs = cryptroot.content;
  subvolumes = btrfs.subvolumes;
  swapDevice = builtins.head config.swapDevices;
in
assert config.networking.hostName == "saturnine";
assert disk.device == "/dev/disk/by-id/CHANGE-ME-saturnine-system-disk";
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
assert lib.elem "kvm-intel" config.boot.kernelModules;
assert config.hardware.enableRedistributableFirmware;
assert config.hardware.nvidia.open == false;
assert config.hardware.nvidia.prime.offload.enable;
assert config.hardware.nvidia.prime.intelBusId == "PCI:0:2:0";
assert config.hardware.nvidia.prime.nvidiaBusId == "PCI:1:0:0";
assert lib.elem "nvidia-kernel-modules" config.theorem.nixos.base.nix.unfreePackageNames;
assert lib.elem "nvidia-x11" config.theorem.nixos.base.nix.unfreePackageNames;
assert lib.elem "nvidia-settings" config.theorem.nixos.base.nix.unfreePackageNames;
assert lib.elem "spotify" config.theorem.nixos.base.nix.unfreePackageNames;
assert lib.elem "vscode" config.theorem.nixos.base.nix.unfreePackageNames;
assert config.theorem.nixos.base.persistence.storage.manageFileSystems == false;
assert config.theorem.nixos.base.persistence.root.mode == "btrfs";
assert config.boot.initrd.systemd.services.rollback-root.before == [ "sysroot.mount" ];
assert config.fileSystems."/nix".neededForBoot;
assert config.fileSystems."/nix/persist".neededForBoot;
pkgs.runCommand "saturnine-disko-boundary" { } ''
  touch "$out"
''
