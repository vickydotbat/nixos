{ pkgs, ... }:

let
  gimpPluginPython = pkgs.python3.withPackages (
    ps: with ps; [
      pygobject3
    ]
  );

  myGimp = pkgs.symlinkJoin {
    name = "gimp3-with-plt-python";
    paths = [ pkgs.gimp3-with-plugins ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/gimp \
        --set PATH ${
          pkgs.lib.makeBinPath [
            gimpPluginPython
            pkgs.coreutils
            pkgs.bash
          ]
        } \
        --prefix GI_TYPELIB_PATH : ${
          pkgs.lib.makeSearchPath "lib/girepository-1.0" [
            pkgs.gimp
            pkgs.gtk3
            pkgs.gegl
            pkgs.babl
          ]
        }
    '';
  };
in
{
  home.packages = [
    myGimp
  ];
}
