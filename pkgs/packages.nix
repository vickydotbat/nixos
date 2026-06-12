{ pkgs }:

{
  blender-402-bin = pkgs.callPackage ./blender-402-bin.nix { };
  cleanmodels = pkgs.callPackage ./cleanmodels.nix { };
  gimp3-custom = pkgs.callPackage ./gimp3-custom.nix { };
  neverwinter-nim = pkgs.callPackage ./neverwinter-nim.nix { };
  nwnexplorer = pkgs.callPackage ./nwnexplorer.nix { };
  nwtoolset = pkgs.callPackage ./nwtoolset.nix { };
  fallow = pkgs.callPackage ./fallow.nix { };
}
