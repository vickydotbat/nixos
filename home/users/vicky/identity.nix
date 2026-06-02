{ config, ... }:
let
  flakeDir = "${config.home.homeDirectory}/Repositories/nixos-configuration";
in
{
  home.username = "vicky";
  home.homeDirectory = "/home/vicky";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  home.enableNixpkgsReleaseCheck = false;

  home.sessionVariables = {
    NIXOS_CONFIG_FLAKE = flakeDir;
  };
}
