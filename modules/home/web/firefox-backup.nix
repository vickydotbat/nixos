{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.web.firefox-backup;
in
{
  options.theorem.home.web.firefox-backup.enable = lib.mkEnableOption "Firefox profile backup tools";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/web/firefox-backup.nix args);
}
