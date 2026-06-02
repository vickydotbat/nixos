{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.bat;
in
{
  options.theorem.home.shell.bat.enable = lib.mkEnableOption "bat";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/bat.nix args);
}
