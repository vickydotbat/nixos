{
  pkgs,
  nwtoolset,
}:

pkgs.runCommand "nwtoolset-wine-boundary"
  {
    nativeBuildInputs = [ pkgs.ripgrep ];
    inherit nwtoolset;
  }
  ''
    wrapper="$nwtoolset/bin/nwtoolset"

    if rg --fixed-strings 'winetricks' "$wrapper"; then
      cat >&2 <<'EOF'
    NWToolset must not gate launch on a winetricks Mono verb. Current winetricks
    releases expose forcemono/remove_mono, but not a mono installer verb, so this
    blocks the launcher before the toolset executable can start.
    EOF
      exit 1
    fi

    rg --fixed-strings 'exec ${pkgs.wineWow64Packages.staging}/bin/wine "$exe" "$@"' "$wrapper"

    touch "$out"
  ''
