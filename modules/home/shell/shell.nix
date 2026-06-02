{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.shell;
in
{
  options.theorem.home.shell.shell.enable = lib.mkEnableOption "interactive shell";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/shell.nix args);
}
