{
  fetchurl,
  lib,
  runtimeShell,
  stdenvNoCC,
  unzip,
  wineWow64Packages,
  util-linux,
  coreutils,
  nwnInstallDir ? "$HOME/.local/share/Steam/steamapps/common/Neverwinter Nights",
  winePrefix ? "$HOME/.local/share/wineprefixes/nwnexplorer",
}:

let
  escapeHereDoc = lib.replaceStrings [ "$" "`" "\\" ] [ "\\$" "\\`" "\\\\" ];

  wine = wineWow64Packages.staging;
  runtimeNwnInstallDir = escapeHereDoc nwnInstallDir;
  runtimeWinePrefix = escapeHereDoc winePrefix;
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

        cat > $out/bin/nwn_explorer <<EOF
    #!${runtimeShell}
    set -euo pipefail

    export WINEPREFIX="\''${WINEPREFIX:-${runtimeWinePrefix}}"
    export WINEDEBUG="-all"
    export WINEDLLOVERRIDES="mscoree,mshtml="

    nwn_install_dir="${runtimeNwnInstallDir}"
    exe="$exe"

    state_dir="\''${XDG_STATE_HOME:-\$HOME/.local/state}/nwnexplorer"
    log_file="\$state_dir/wine.log"

    ${coreutils}/bin/mkdir -p "\$state_dir"
    exec >>"\$log_file" 2>&1

    echo
    echo "=== launching nwnexplorer at \$(${coreutils}/bin/date) ==="
    echo "WINEPREFIX=\$WINEPREFIX"
    echo "nwn_install_dir=\$nwn_install_dir"
    echo "exe=\$exe"

    if [ ! -f "\$exe" ]; then
      echo "Could not find nwnexplorer.exe:"
      echo "  \$exe"
      exit 1
    fi

    if [ ! -d "\$nwn_install_dir" ]; then
      echo "Could not find Neverwinter Nights install directory:"
      echo "  \$nwn_install_dir"
      exit 1
    fi

    prefix_parent="\$(${coreutils}/bin/dirname "\$WINEPREFIX")"
    lock_file="\$prefix_parent/.nwnexplorer-wineprefix.lock"

    ${coreutils}/bin/mkdir -p "\$prefix_parent"

    (
      ${util-linux}/bin/flock 9

      if [ ! -f "\$WINEPREFIX/system.reg" ]; then
        echo "Initializing Wine prefix..."

        ${wine}/bin/wineboot -u
      fi

      echo "Writing NWN Explorer registry configuration..."

      nwn_dir_wine="\$(${wine}/bin/winepath -w "\$nwn_install_dir/")"

      ${wine}/bin/wine reg add "HKCU\\Software\\Torlack\\nwnexplorer" \\
        /v NwnDirectory \\
        /t REG_SZ \\
        /d "\$nwn_dir_wine" \\
        /f
    ) 9>"\$lock_file"

    echo "Starting NWN Explorer..."
    exec ${wine}/bin/wine "\$exe" "\$@"
    EOF

        chmod +x $out/bin/nwn_explorer

        mkdir -p $out/share/applications

        cat > $out/share/applications/nwnexplorer.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=NWN Explorer
    GenericName=Neverwinter Nights Resource Browser
    Comment=Browse and extract Neverwinter Nights resources
    Exec=$out/bin/nwn_explorer
    Icon=applications-utilities
    Terminal=false
    Categories=Development;
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
