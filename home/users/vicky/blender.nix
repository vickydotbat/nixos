{ pkgs, ... }:

{
  home.packages = with pkgs; [
    blender
  ];

  home.persistence."/nix/persist" = {
    directories = [
      "Blender"
    ];
  };
}
