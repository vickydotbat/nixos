{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.starship;
in
{
  options.theorem.home.shell.starship.enable = lib.mkEnableOption "Starship prompt";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/starship.nix args);
}
