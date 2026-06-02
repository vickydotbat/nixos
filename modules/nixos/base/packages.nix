{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.base.packages;
in
{
  options.theorem.nixos.base.packages.enable = lib.mkEnableOption "base system package set";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nano
      git
      zip
      unzip
      unrar
      p7zip
      e2fsprogs
      btrfs-progs
      nvme-cli
      smartmontools

      wineWow64Packages.staging
    ];
  };
}
