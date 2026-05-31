{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.vicky.nixos.virtualisation.nix-ld;
in
{
  options.vicky.nixos.virtualisation.nix-ld.enable =
    lib.mkEnableOption "nix-ld compatibility libraries";

  config = lib.mkIf cfg.enable {
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
  };
}
