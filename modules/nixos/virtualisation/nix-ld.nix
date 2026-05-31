{ pkgs, ... }:

{
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    libGL
    libglvnd
    libX11
    libXext
    libXrender
    libxcb
    libXau
    libXdmcp
    zlib
    glib
    fontconfig
    freetype
  ];
}
