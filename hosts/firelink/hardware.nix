{
  inputs,
  lib,
  modulesPath,
  ...
}:

# Firelink is an MSI Cyborg 15 A13VE laptop: Intel Core i7-13620H, 16 GiB
# RAM, 1 TB internal disk, Intel UHD integrated graphics, NVIDIA GeForce RTX
# 4050 Laptop GPU with 6 GiB VRAM, Italian keyboard, x86_64, and UEFI boot.
# NVIDIA policy is left explicit until the first real hardware probe; the Intel
# CPU and SSD facts are safe to declare now.
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
