{
  config,
  lib,
  ...
}:
# Obsidian is a user knowledge-work surface. The reusable module installs the
# application and persists the vault directory only when Home persistence is
# already part of the user's theorem.
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
