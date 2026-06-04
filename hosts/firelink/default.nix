{
  inputs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    ./profiles.nix
    ./storage.nix
    ./system.nix
  ];
}
