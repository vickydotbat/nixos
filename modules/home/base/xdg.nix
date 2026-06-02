{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.base.xdg;
in
{
  options.theorem.home.base.xdg.enable = lib.mkEnableOption "XDG user directories";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/xdg.nix args);
}
