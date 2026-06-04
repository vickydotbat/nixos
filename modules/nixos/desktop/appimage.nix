{ config, lib, ... }:

# AppImage support is a compatibility surface, not a desktop default. Enabling
# it adds binfmt/FUSE convenience for hosts that deliberately run AppImages.
let
  cfg = config.theorem.nixos.desktop.appimage;
in
{
  options.theorem.nixos.desktop.appimage.enable = lib.mkEnableOption "AppImage usability";

  config = lib.mkIf cfg.enable {
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
  };
}
