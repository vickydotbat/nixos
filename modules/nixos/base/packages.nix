{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: These are global defaults, most of them (maybe except the disk tools and wine). Reconsider this being a toggle and instead just set up good global defaults.
let
  cfg = config.theorem.nixos.base.packages;
in
{
  options.theorem.nixos.base.packages.enable = lib.mkEnableOption "base system package set";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      nano
      unzip
      zip
    ];
  };
}
