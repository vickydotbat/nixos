{
  lib,
  stdenvNoCC,
  runtimeShell,
  wineWow64Packages,
  util-linux,
  coreutils,
  nwnInstallDir ? "$HOME/.local/share/Steam/steamapps/common/Neverwinter Nights",
  winePrefix ? "$HOME/.local/share/wineprefixes/nwtoolset",
}:

let
  wine = wineWow64Packages.staging;
in
stdenvNoCC.mkDerivation {
  pname = "nwtoolset";
  version = "steam";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        mkdir -p $out/share/applications

        cat > $out/bin/nwtoolset <<'EOF'
    #!${runtimeShell}
    set -euo pipefail

    export WINEPREFIX="${winePrefix}"
    export WINEDEBUG="-all"

    exe="${nwnInstallDir}/bin/win32/nwtoolset.exe"

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/nwtoolset"
    log_file="$state_dir/wine.log"

    ${coreutils}/bin/mkdir -p "$state_dir"
    exec >>"$log_file" 2>&1

    echo
    echo "=== launching nwtoolset at $("${coreutils}/bin/date") ==="
    echo "WINEPREFIX=$WINEPREFIX"
    echo "exe=$exe"

    if [ ! -f "$exe" ]; then
      echo "Could not find nwtoolset.exe:"
      echo "  $exe"
      exit 1
    fi

    prefix_parent="$(${coreutils}/bin/dirname "$WINEPREFIX")"
    lock_file="$prefix_parent/.nwtoolset-wineprefix.lock"

    ${coreutils}/bin/mkdir -p "$prefix_parent"

    (
      ${util-linux}/bin/flock 9

      if [ ! -f "$WINEPREFIX/system.reg" ]; then
        echo "Initializing Wine prefix..."

        ${wine}/bin/wineboot -u
      fi
    ) 9>"$lock_file"

    echo "Starting NWToolset..."
    exec ${wine}/bin/wine "$exe" "$@"
    EOF

        chmod +x $out/bin/nwtoolset

        cat > $out/share/applications/nwtoolset.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Aurora Toolset
    GenericName=Neverwinter Nights Toolset
    Comment=Create content for Neverwinter Nights
    Exec=$out/bin/nwtoolset
    Icon=applications-development
    Terminal=false
    Categories=Development;
    EOF

        runHook postInstall
  '';

  meta = {
    description = "Wine launcher for the Neverwinter Nights Aurora Toolset";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    mainProgram = "nwtoolset";
  };
}
