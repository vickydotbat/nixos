{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.appimage;
in
{
  options.vicky.nixos.desktop.appimage.enable = lib.mkEnableOption "Appimage usability";

  config = lib.mkIf cfg.enable {
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
  };
}
