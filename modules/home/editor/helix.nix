{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.editor.helix;
in
{
  options.theorem.home.editor.helix.enable = lib.mkEnableOption "Helix editor";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/helix.nix args);
}
