{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    ripgrep
    jq
    fastfetch
    blender
  ];
}
