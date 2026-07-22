{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  libGL,
  libxkbcommon,
  wayland,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
}:

rustPlatform.buildRustPackage {
  pname = "aurora-hak-explorer";
  version = "0.2.1-unstable-2026-07-15";

  src = fetchFromGitHub {
    owner = "Winternite";
    repo = "Aurora-Hak-Explorer";
    rev = "f92d4825fa1d9836a91465676d5947b6f12761a8";
    hash = "sha256-T5C/eytQm+YLiO6Xvbh9cYJ2q6CwfR3ERDpSuPoEgHs=";
  };

  cargoHash = "sha256-wBq/+KSRbTemUUL5Wn3beYaierXIGzgNNwigZhGQs9c=";

  nativeBuildInputs = [ makeWrapper ];

  # eframe/winit dlopen these at runtime instead of linking them.
  postFixup = ''
    wrapProgram $out/bin/aurora-hak-explorer \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libGL
          libxkbcommon
          wayland
          libx11
          libxcursor
          libxi
          libxrandr
        ]
      }

    mkdir -p $out/share/applications
    cat > $out/share/applications/aurora-hak-explorer.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Aurora Hak Explorer
    GenericName=Neverwinter Nights Archive Editor
    Comment=Browse and edit HAK/ERF/MOD/SAV archives
    Exec=$out/bin/aurora-hak-explorer
    Icon=applications-utilities
    Terminal=false
    Categories=Development;
    EOF
  '';

  meta = {
    description = "Native HAK/ERF archive explorer for Neverwinter Nights";
    homepage = "https://github.com/Winternite/Aurora-Hak-Explorer";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "aurora-hak-explorer";
  };
}
