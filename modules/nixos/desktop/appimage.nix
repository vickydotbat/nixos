{ config, lib, ... }:

let
  cfg = config.theorem.nixos.desktop.appimage;
in
{
  options.theorem.nixos.desktop.appimage.enable = lib.mkEnableOption "Appimage usability";

  config = lib.mkIf cfg.enable {
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
  };
}
