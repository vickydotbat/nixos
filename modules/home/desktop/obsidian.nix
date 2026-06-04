{
  config,
  lib,
  options,
  ...
}:
# Obsidian is a user knowledge-work surface. The reusable module installs the
# application and persists the vault directory only when Home persistence is
# already part of the user's theorem.
let
  cfg = config.theorem.home.desktop.obsidian;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.desktop.obsidian.enable = lib.mkEnableOption "Obsidian";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.obsidian.enable = true;
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              "Obsidian"
            ];
          };
    })
  ];
}
