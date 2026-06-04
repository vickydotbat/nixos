{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  config = inputs.self.nixosConfigurations.solanine.config;
  adminGroups = config.users.users.admin.extraGroups or [ ];
  vickyGroups = config.users.users.vicky.extraGroups or [ ];
  guestGroups = config.users.users.guest.extraGroups or [ ];
in
assert config.theorem.nixos.virtualisation.libvirt.enable;
assert config.virtualisation.libvirtd.enable;
assert config.programs.virt-manager.enable;
assert config.virtualisation.spiceUSBRedirection.enable;
assert config.virtualisation.libvirtd.qemu.swtpm.enable;
assert config.virtualisation.libvirtd.qemu.runAsRoot == false;
assert lib.elem "libvirtd" adminGroups;
assert lib.elem "libvirtd" vickyGroups;
assert !(lib.elem "libvirtd" guestGroups);
pkgs.runCommand "solanine-libvirt-boundary" { } ''
  touch "$out"
''
