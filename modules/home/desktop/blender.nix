{
  config,
  lib,
  options,
  pkgs,
  ...
}:
# Blender is a user working-surface package with versioned configuration state.
# The reusable module installs the ordinary package and persists only the paths
# Blender expects; custom builds and plugin sets stay in user profiles.
let
  cfg = config.theorem.home.desktop.blender;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.desktop.blender = {
    enable = lib.mkEnableOption "Blender";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.blender;
      description = ''
        Blender package installed by this Home profile. Override this when a
        project needs a pinned Blender build instead of the current nixpkgs
        default.
      '';
    };

    persistedConfigVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ (lib.versions.majorMinor cfg.package.version) ];
      defaultText = lib.literalExpression "[ (lib.versions.majorMinor theorem.home.desktop.blender.package.version) ]";
      description = ''
        Blender configuration version directories persisted under
        `~/.config/blender`. The default follows the selected package version;
        add older versions here before changing packages if a project still
        needs that state after an impermanent reboot.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              "Blender"
            ]
            ++ map (version: ".config/blender/${version}") cfg.persistedConfigVersions;
          };
    })
  ];
}
