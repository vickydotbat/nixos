{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.plasma;
in
{
  options.theorem.home.desktop.plasma.enable = lib.mkEnableOption "Plasma user configuration";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/plasma.nix args);
}
