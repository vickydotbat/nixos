{ pkgs, lib, ... }:

let
  blender = pkgs.blender;
  blenderConfigVersion = lib.versions.majorMinor blender.version;
in
{
  home.packages = [
    blender
  ];

  home.persistence."/nix/persist" = {
    directories = [
      "Blender"
      ".config/blender/${blenderConfigVersion}"
    ];
  };
}
