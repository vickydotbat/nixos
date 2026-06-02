{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.base.fonts;
in
{
  options.theorem.home.base.fonts.enable = lib.mkEnableOption "font packages";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/fonts.nix args);
}
