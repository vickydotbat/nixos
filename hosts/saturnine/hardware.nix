# Saturnine is an Intel laptop with 16 GiB of RAM and an NVIDIA discrete GPU.
# The active posture is PRIME offload: the Intel GPU carries the desktop, and
# NVIDIA is summoned explicitly for workloads that need it. Re-check the bus IDs
# with `lspci` during installation before replacing the placeholder disk IDs in
# storage.nix.
{
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "vmd"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  hardware.enableRedistributableFirmware = true;

  hardware.nvidia = {
    # Keep the proprietary kernel modules until the exact GPU generation is
    # confirmed. Turing-or-newer hardware may move to `true` after a boot test.
    open = lib.mkDefault false;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # The previous installation reported fragile EFI variable writes. Keep boot
  # updates file-backed until a fresh firmware test proves NVRAM writes are safe.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
}
