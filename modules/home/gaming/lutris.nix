{
  config,
  lib,
  options,
  pkgs,
  ...
}:
# Lutris lives entirely in the Home profile: Home Manager installs it via
# programs.lutris, and its runner database plus Wine prefixes sit in the home
# directory. Persistence is declared here too, or every installed game
# evaporates on reboot under impermanence - including ~/.local/share/wineprefixes
# (Lutris/Proton prefixes, e.g. nwn.nix's winePrefixDir) and bare ~/.wine
# (created by the System wine runner or manual `wine` invocations).
let
  cfg = config.theorem.home.gaming.lutris;

  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.gaming.lutris.enable = lib.mkEnableOption "Lutris";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.lutris.enable = true;

      # A plain `wine` on PATH gives Lutris a "System" runner option, distinct
      # from its downloaded Proton/Wine-GE builds. Some old titles misbehave
      # under those builds in ways a virtual-desktop window fixes, but Lutris
      # refuses virtual-desktop mode for any runner whose path contains
      # "wine-ge" or points into a Proton tree (lutris/runners/wine.py) - the
      # System runner is the escape hatch for that case.
      home.packages = [ pkgs.wineWow64Packages.stable ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && persistenceEnabled) {
        directories = [
          ".config/lutris"
          ".local/share/lutris"
          ".local/share/wineprefixes"
          ".wine"
        ];
      };
    })
  ];
}
