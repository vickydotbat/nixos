{
  bash,
  coreutils,
  at-spi2-core,
  gsettings-desktop-schemas,
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
    (lib.getLib at-spi2-core)
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

  # GTK file/profile chooser widgets abort at startup if GSettings schemas are
  # absent from the wrapped environment.
  gsettingsSchemaPath = lib.concatStringsSep ":" [
    "${gtk3}/share/gsettings-schemas/${gtk3.name}"
    "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
  ];

  gimpCommand = "gimp-${lib.versions.majorMinor (lib.getVersion gimp)}";
  gimpConsoleCommand = "gimp-console-${lib.versions.majorMinor (lib.getVersion gimp)}";

  pluginRuntimePath = lib.makeBinPath [
    gimpPluginPython
    gimp
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
          --prefix XDG_DATA_DIRS : ${gsettingsSchemaPath} \
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
      $out/bin/${gimpCommand} \
      $out/bin/gimp-console \
      $out/bin/gimp-console-3 \
      $out/bin/gimp-console-3.0 \
      $out/bin/${gimpConsoleCommand}

    makeWrapper ${gimp}/bin/gimp $out/bin/${gimpCommand} \
      --set GIMP3_PLUGINDIR "$out/lib/gimp/3.0" \
      --set GIMP3_DATADIR "$out/share/gimp/3.0" \
      --set PATH ${pluginRuntimePath} \
      --prefix XDG_DATA_DIRS : ${gsettingsSchemaPath} \
      --prefix GI_TYPELIB_PATH : ${pluginTypelibPath}
    ln -s ${gimpCommand} $out/bin/gimp
    ln -s ${gimpCommand} $out/bin/gimp-3
    ln -s ${gimpCommand} $out/bin/gimp-3.0

    makeWrapper ${gimp}/bin/gimp-console $out/bin/${gimpConsoleCommand} \
      --set GIMP3_PLUGINDIR "$out/lib/gimp/3.0" \
      --set GIMP3_DATADIR "$out/share/gimp/3.0" \
      --set PATH ${pluginRuntimePath} \
      --prefix XDG_DATA_DIRS : ${gsettingsSchemaPath} \
      --prefix GI_TYPELIB_PATH : ${pluginTypelibPath}
    ln -s ${gimpConsoleCommand} $out/bin/gimp-console
    ln -s ${gimpConsoleCommand} $out/bin/gimp-console-3
    ln -s ${gimpConsoleCommand} $out/bin/gimp-console-3.0
  '';

  meta = {
    description = "GIMP 3 with Python plugin support and local plugins";
    platforms = lib.platforms.linux;
    mainProgram = "gimp";
  };
}
