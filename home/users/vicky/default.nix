{ ... }:

{
  imports = [
    ./desktop-apps.nix
    ./gimp.nix
    ./git.nix
    ./nwn.nix
    ./packages.nix
    ./spicetify.nix
    ./ssh.nix
  ];

  home.username = "vicky";
  home.homeDirectory = "/home/vicky";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
