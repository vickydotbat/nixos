{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.base.virtualization;
in
{
  options.theorem.home.base.virtualization.enable = lib.mkEnableOption "user virtualization tools";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/virtualization.nix args);
}
