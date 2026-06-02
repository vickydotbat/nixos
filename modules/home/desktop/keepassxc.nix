{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.keepassxc;
in
{
  options.theorem.home.desktop.keepassxc.enable = lib.mkEnableOption "KeePassXC";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/keepassxc.nix args);
}
