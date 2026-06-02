{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.obsidian;
in
{
  options.theorem.home.desktop.obsidian.enable = lib.mkEnableOption "Obsidian";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/obsidian.nix args);
}
