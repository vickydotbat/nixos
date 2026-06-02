{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.web.firefox;
in
{
  options.theorem.home.web.firefox.enable = lib.mkEnableOption "Firefox";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/web/firefox.nix args);
}
