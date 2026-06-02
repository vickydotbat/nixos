{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.ripgrep;
in
{
  options.theorem.home.shell.ripgrep.enable = lib.mkEnableOption "ripgrep";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/ripgrep.nix args);
}
