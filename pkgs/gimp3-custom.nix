{
  bash,
  coreutils,
  gimp,
  gimp3-with-plugins,
  gtk3,
  gegl,
  babl,
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
  symlinkJoin,
}:

let
  gimpPluginPython = python3.withPackages (
    ps: with ps; [
      pygobject3
    ]
  );

  gimpPlugins = stdenvNoCC.mkDerivation {
    pname = "gimp-local-plugins";
    version = "0";

    src = ./gimp-plugins;

    nativeBuildInputs = [
      gimpPluginPython
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gimp/3.0/plug-ins $out/share/gimp/3.0/scripts

      if [ -d plug-ins ]; then
        cp -R plug-ins/. $out/lib/gimp/3.0/plug-ins/
      fi

      if [ -d scripts ]; then
        cp -R scripts/. $out/share/gimp/3.0/scripts/
      fi

      find $out/lib/gimp/3.0/plug-ins -type f \( -name '*.py' -o -name '*.sh' \) -exec chmod +x {} +
      patchShebangs $out/lib/gimp/3.0/plug-ins

      runHook postInstall
    '';
  };
in
symlinkJoin {
  name = "gimp3-custom";
  paths = [
    gimp3-with-plugins
    gimpPlugins
  ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/gimp \
      --set PATH ${
        lib.makeBinPath [
          gimpPluginPython
          coreutils
          bash
        ]
      } \
      --prefix GI_TYPELIB_PATH : ${
        lib.makeSearchPath "lib/girepository-1.0" [
          gimp
          gtk3
          gegl
          babl
        ]
      }
  '';

  meta = {
    description = "GIMP 3 with Python plugin support and local plugins";
    platforms = lib.platforms.linux;
    mainProgram = "gimp";
  };
}
