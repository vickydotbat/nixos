{
  inputs,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    ./profiles.nix
    ./secrets.nix
    ./storage.nix
    ./system.nix
  ];
}
