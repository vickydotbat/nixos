{
  bash,
  coreutils,
  gdk-pixbuf,
  gimp,
  gimp3-with-plugins,
  gexiv2,
  glib,
  gobject-introspection,
  harfbuzz,
  gtk3,
  gegl,
  babl,
  lib,
  makeWrapper,
  pango,
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

  pluginTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    (lib.getLib babl)
    (lib.getLib gdk-pixbuf)
    (lib.getLib gegl)
    (lib.getLib gexiv2)
    (lib.getLib gimp)
    (lib.getLib glib)
    (lib.getLib gobject-introspection)
    (lib.getLib harfbuzz)
    (lib.getLib gtk3)
    (lib.getLib pango)
  ];

  pluginRuntimePath = lib.makeBinPath [
    gimpPluginPython
    coreutils
    bash
  ];

  gimpPlugins = stdenvNoCC.mkDerivation {
    pname = "gimp-local-plugins";
    version = "0";

    src = ./gimp-plugins;

    nativeBuildInputs = [
      gimpPluginPython
      makeWrapper
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

      while IFS= read -r plugin; do
        wrapProgram "$plugin" \
          --set PATH ${pluginRuntimePath} \
          --prefix GI_TYPELIB_PATH : ${pluginTypelibPath}
      done < <(find $out/lib/gimp/3.0/plug-ins -type f \( -name '*.py' -o -name '*.sh' \))

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
    rm -f \
      $out/bin/gimp \
      $out/bin/gimp-3 \
      $out/bin/gimp-3.0 \
      $out/bin/gimp-console \
      $out/bin/gimp-console-3 \
      $out/bin/gimp-console-3.0

    makeWrapper ${gimp}/bin/gimp $out/bin/gimp-3.0 \
      --set GIMP3_PLUGINDIR "$out/lib/gimp/3.0" \
      --set GIMP3_DATADIR "$out/share/gimp/3.0" \
      --set PATH ${pluginRuntimePath} \
      --prefix GI_TYPELIB_PATH : ${pluginTypelibPath}
    ln -s gimp-3.0 $out/bin/gimp
    ln -s gimp-3.0 $out/bin/gimp-3

    makeWrapper ${gimp}/bin/gimp-console $out/bin/gimp-console-3.0 \
      --set GIMP3_PLUGINDIR "$out/lib/gimp/3.0" \
      --set GIMP3_DATADIR "$out/share/gimp/3.0" \
      --set PATH ${pluginRuntimePath} \
      --prefix GI_TYPELIB_PATH : ${pluginTypelibPath}
    ln -s gimp-console-3.0 $out/bin/gimp-console
    ln -s gimp-console-3.0 $out/bin/gimp-console-3
  '';

  meta = {
    description = "GIMP 3 with Python plugin support and local plugins";
    platforms = lib.platforms.linux;
    mainProgram = "gimp";
  };
}
