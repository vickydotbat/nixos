{
  fetchurl,
  lib,
  runtimeShell,
  stdenvNoCC,
  unzip,
  wineWow64Packages,
  writeText,
  nwnInstallDir ? "$HOME/.local/share/Steam/steamapps/common/Neverwinter Nights",
}:

let
  toWineZPath = path: "Z:${lib.replaceStrings [ "/" ] [ "\\\\" ] path}";

  nwnDirectoryWine = "${toWineZPath nwnInstallDir}\\\\";

  nwnexplorerReg = writeText "nwnexplorer.reg" ''
    Windows Registry Editor Version 5.00

    [HKEY_CURRENT_USER\Software\Torlack\nwnexplorer]
    "NwnDirectory"="${nwnDirectoryWine}"
  '';
in
stdenvNoCC.mkDerivation rec {
  pname = "nwnexplorer";
  version = "1.8.5";
  assetVersion = "185";

  src = fetchurl {
    url = "https://github.com/virusman/nwnexplorer/releases/download/${version}/nwnexplorer-${assetVersion}.zip";
    hash = "sha256-vc/AgH/E4o/FDsP0QiWMloXkVQ4c42njRpLwOf+6klc=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/opt/nwnexplorer
        cp -r ./* $out/opt/nwnexplorer/

        exe="$(find $out/opt/nwnexplorer -iname 'nwnexplorer.exe' | head -n1)"

        if [ -z "$exe" ]; then
          echo "Could not find nwnexplorer.exe in release archive"
          find $out/opt/nwnexplorer -maxdepth 3 -type f
          exit 1
        fi

        mkdir -p $out/bin

        cat > $out/bin/nwnexplorer <<EOF
    #!${runtimeShell}
    set -e

    if [ -z "''${WINEPREFIX:-}" ]; then
      export WINEPREFIX="\$HOME/.local/share/wineprefixes/nwnexplorer"
    fi

    export WINEDEBUG="-all"
    export WINEDLLOVERRIDES="mscoree,mshtml="

    mkdir -p "\$WINEPREFIX"

    ${wineWow64Packages.staging}/bin/wine regedit /S ${nwnexplorerReg}

    exec ${wineWow64Packages.staging}/bin/wine "$exe" "\$@"
    EOF

        chmod +x $out/bin/nwnexplorer

        mkdir -p $out/share/applications

        cat > $out/share/applications/nwnexplorer.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=NWN Explorer
    GenericName=Neverwinter Nights Resource Browser
    Comment=Browse and extract Neverwinter Nights resources
    Exec=$out/bin/nwnexplorer
    Icon=applications-utilities
    Terminal=false
    Categories=Development;Game;Utility;
    EOF

        runHook postInstall
  '';

  meta = {
    description = "NWN Explorer resource browser for Neverwinter Nights";
    homepage = "https://github.com/virusman/nwnexplorer";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "nwnexplorer";
  };
}
