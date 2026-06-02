{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.gimp;
in
{
  options.theorem.home.desktop.gimp.enable = lib.mkEnableOption "GIMP";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/gimp.nix args);
}
