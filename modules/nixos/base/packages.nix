{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.vicky.nixos.base.packages;
in
{
  options.vicky.nixos.base.packages.enable = lib.mkEnableOption "base system package set";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ghostty
      nano
      git
      vulkan-tools
      steam-run
      zip
      unzip
      unrar
      p7zip
      nix-init
      wineWow64Packages.staging
      nix-index
    ];
  };
}
