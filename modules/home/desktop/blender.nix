{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.blender;
in
{
  options.theorem.home.desktop.blender.enable = lib.mkEnableOption "Blender";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/blender.nix args);
}
