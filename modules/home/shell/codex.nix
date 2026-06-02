{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.codex;
in
{
  options.theorem.home.shell.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/codex.nix args);
}
