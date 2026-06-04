# Generated baseline. host-specific hardware posture may be lifted into focused
# modules when the mechanism becomes reusable.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
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
    # `0x10`. `0x12` is the next documented AMDGPU display workaround to test.
    # Keep this host-scoped until real uptime proves the rite.
    "amdgpu.dcdebugmask=0x12"

    # This desktop is not battery-bound. Keep the discrete GPU out of runtime
    # power-down while diagnosing "no outputs" freezes; remove if idle power or
    # thermals become the sharper failure mode.
    "amdgpu.runpm=0"
  ];

  # Host platform and CPU firmware posture for this machine.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
