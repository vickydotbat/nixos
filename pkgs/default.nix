{ pkgs }:

{
  blender-402-bin = pkgs.callPackage ./blender-402-bin.nix { };
  cleanmodels = pkgs.callPackage ./cleanmodels.nix { };
  neverwinter-nim = pkgs.callPackage ./neverwinter-nim.nix { };
  nwnexplorer = pkgs.callPackage ./nwnexplorer.nix { };
}
