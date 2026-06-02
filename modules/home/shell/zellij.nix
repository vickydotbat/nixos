{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.zellij;
in
{
  options.theorem.home.shell.zellij.enable = lib.mkEnableOption "Zellij terminal multiplexer";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/zellij.nix args);
}
