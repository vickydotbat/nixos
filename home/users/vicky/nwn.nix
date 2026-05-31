{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.blender-402-bin
    pkgs.cleanmodels
    pkgs.neverwinter-nim
    (pkgs.nwnexplorer.override {
      nwnInstallDir = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/Neverwinter Nights";
    })
  ];
}
