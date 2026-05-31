{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./persistence.nix
    ../../modules/nixos/base/boot.nix
    ../../modules/nixos/base/locale.nix
    ../../modules/nixos/base/networking.nix
    ../../modules/nixos/base/nix.nix
    ../../modules/nixos/base/packages.nix
    ../../modules/nixos/base/ssh.nix
    ../../modules/nixos/base/users.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/bluetooth.nix
    ../../modules/nixos/desktop/graphics.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/gaming/steam.nix
    ../../modules/nixos/virtualisation/nix-ld.nix
    ../../modules/nixos/virtualisation/podman.nix
  ];

  networking.hostName = "solanine";

  system.stateVersion = "25.11";
}
