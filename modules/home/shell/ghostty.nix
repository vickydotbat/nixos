{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.ghostty;
in
{
  options.theorem.home.shell.ghostty.enable = lib.mkEnableOption "Ghostty terminal";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/ghostty.nix args);
}
