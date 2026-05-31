{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    blender
  ];
}
