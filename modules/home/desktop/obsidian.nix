{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.desktop.obsidian;
in
{
  options.theorem.home.desktop.obsidian.enable = lib.mkEnableOption "Obsidian";

  config = lib.mkIf cfg.enable {
    programs.obsidian.enable = true;

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        "Obsidian"
      ];
    };
  };
}
