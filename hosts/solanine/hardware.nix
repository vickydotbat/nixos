# Generated baseline. host-specific hardware posture may be lifted into focused
# modules when the mechanism becomes reusable.
{
  inputs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Solanine hardware discovery. Disk and persistence policy lives in
  # storage.nix; reusable hardware mechanisms should be extracted only after a
  # second host proves the shape.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [
    # Forces the driver to ignore the integrated display block entirely
    "amdgpu.sg_display=0"

    # Solanine still sees Plasma/Wayland `flip_done timed out` freezes with
    # `0x10` and `0x12`. `0x52` keeps PSR and stutter disabled and also disables
    # AMD Display Core multi-plane offloading after plane commit timeouts were
    # observed. Keep this host-scoped until real uptime proves the rite.
    "amdgpu.dcdebugmask=0x52"

    # This desktop is not battery-bound. Keep the discrete GPU out of runtime
    # power-down while diagnosing "no outputs" freezes; remove if idle power or
    # thermals become the sharper failure mode.
    "amdgpu.runpm=0"
  ];

  # Host platform for this machine. AMD CPU firmware, pstate, GPU, and SSD
  # defaults are imported from nixos-hardware above; Solanine keeps only the
  # local facts and active display-crash mitigations here.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  nixpkgs.config.rocmSupport = true; # TODO: Base this on the system, globally?
}
