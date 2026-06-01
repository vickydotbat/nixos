{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.plasma;
in
{
  options.vicky.nixos.desktop.plasma.enable = lib.mkEnableOption "Plasma desktop profile";

  config = lib.mkIf cfg.enable {
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
    programs.kdeconnect.enable = true;

    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
  };
}
