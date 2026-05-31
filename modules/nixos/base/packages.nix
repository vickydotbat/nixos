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
      nano
      git
      nix-index
      zip
      unzip
      unrar
      p7zip

      vulkan-tools
      steam-run
      nix-init
      wineWow64Packages.staging
    ];
  };
}
