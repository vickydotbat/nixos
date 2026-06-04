{
  config,
  lib,
  pkgs,
  ...
}:
# Blender is a user working-surface package with versioned configuration state.
# The reusable module installs the ordinary package and persists only the paths
# Blender expects; custom builds and plugin sets stay in user profiles.
let
  cfg = config.theorem.home.desktop.blender;

  # Default mechanism, kept in the reusable module; home/ may override it.
  blender = pkgs.blender;
  blenderConfigVersion = lib.versions.majorMinor blender.version; # TODO: Be warned, if blender's version changes, user configurations on impermanent systems will disappear. Preserving only active versions is the intended mantra (as some hosts use multiple versions), but how can we guardrail this? Option 1: add something here that warns the user about impermanence risks upon an update where the version changes. Option 2: Persist .config/blender for all installations of blender in a way that doesn't collide. See the other blender-420 module.
in
{
  options.theorem.home.desktop.blender.enable = lib.mkEnableOption "Blender";

  config = lib.mkIf cfg.enable {
    home.packages = [
      blender
    ];

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        "Blender"
        ".config/blender/${blenderConfigVersion}"
      ];
    };
  };
}
