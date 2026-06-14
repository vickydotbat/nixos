{
  gimp3-custom,
  pkgs,
}:

pkgs.runCommand "gimp-custom-wrapper-boundary"
  {
    nativeBuildInputs = [ pkgs.ripgrep ];
  }
  ''
    for launcher in gimp-3.2 gimp-console-3.2; do
      path="${gimp3-custom}/bin/$launcher"

      if [ -L "$path" ]; then
        cat >&2 <<EOF
    $launcher must be owned by gimp3-custom's wrapper. If it remains a symlink
    from gimp3-with-plugins, desktop launchers can bypass the repaired GIMP
    runtime environment.
    EOF
        exit 1
      fi

      rg --fixed-strings 'GIMP3_PLUGINDIR=' "$path"
      rg --fixed-strings 'XDG_DATA_DIRS=' "$path"
      rg --fixed-strings 'GI_TYPELIB_PATH=' "$path"
    done

    touch "$out"
  ''
