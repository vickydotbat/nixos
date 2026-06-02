{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.base.persistence;
in
{
  options.theorem.home.base.persistence.enable = lib.mkEnableOption "home persistence";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/persistence.nix args);
}
