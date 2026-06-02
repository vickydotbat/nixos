{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.discord;
in
{
  options.theorem.home.desktop.discord.enable = lib.mkEnableOption "Discord";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/discord.nix args);
}
