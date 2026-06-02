{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.desktop.spicetify;
in
{
  options.theorem.home.desktop.spicetify.enable = lib.mkEnableOption "Spicetify";

  imports = [ args.inputs.spicetify-nix.homeManagerModules.spicetify ];

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/spicetify.nix args);
}
