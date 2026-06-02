{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.git;
in
{
  options.theorem.home.shell.git.enable = lib.mkEnableOption "Git";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/git.nix args);
}
