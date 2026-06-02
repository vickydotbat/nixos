{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.shell.nix-index;
in
{
  options.theorem.home.shell.nix-index.enable = lib.mkEnableOption "nix-index";

  imports = [
    args.inputs.nix-index-database.homeModules.nix-index
  ];

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/shell/nix-index.nix args);
}
