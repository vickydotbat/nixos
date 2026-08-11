{ pkgs }:

{
  aurora-hak-explorer = pkgs.callPackage ./aurora-hak-explorer.nix { };
  blender-402-bin = pkgs.callPackage ./blender-402-bin.nix { };
  blender-mcp = pkgs.callPackage ./blender-mcp.nix { };
  cleanmodels = pkgs.callPackage ./cleanmodels.nix { };
  dcg = pkgs.callPackage ./dcg.nix { };
  gimp3-custom = pkgs.callPackage ./gimp3-custom.nix { };
  neverwinter-nim = pkgs.callPackage ./neverwinter-nim.nix { };
  nwnexplorer = pkgs.callPackage ./nwnexplorer.nix { };
  omp = pkgs.callPackage ./omp/package.nix { };
  nwtoolset = pkgs.callPackage ./nwtoolset.nix { };
  rtk = pkgs.callPackage ./rtk.nix { };
  fallow = pkgs.callPackage ./fallow.nix { };
  # Shadows nixpkgs' tea; see pkgs/tea.nix for why and when to drop it.
  tea = pkgs.callPackage ./tea.nix { };
}
