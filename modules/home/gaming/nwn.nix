{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.gaming.nwn;
in
{
  options.theorem.home.gaming.nwn.enable = lib.mkEnableOption "Neverwinter Nights tooling";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/gaming/nwn.nix args);
}
