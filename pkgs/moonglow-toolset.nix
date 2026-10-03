{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  alsa-lib,
  libGL,
  libxkbcommon,
  vulkan-loader,
  wayland,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
}:

# Pinned to a release until the upstream flake lands
# (https://github.com/jadzziaa/moonglow-toolset/pull/2). Once it merges, swap
# this recipe for a flake input, so `nix flake update` pulls the latest build.
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "moonglow-toolset";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "jadzziaa";
    repo = "moonglow-toolset";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dGi0mvrXYsnITsseJiVGwbsLFTtAGFH1ZLgi4hmgyMs=";
  };

  cargoHash = "sha256-Sds9d7+QXPIpO/ASzdCFYj7tY/kbya3cGbSC5WbKfz4=";

  # The GUI and the command-line tools. The workspace also holds the corpus
  # test crate, which only matters beside a game install.
  cargoBuildFlags = [
    "-p"
    "moonglow"
    "-p"
    "mg"
  ];

  # The corpus, engine and egui snapshot tests need the game install and a
  # GPU, neither of which exists inside the build sandbox.
  doCheck = false;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  # rodio plays the game's sounds through ALSA.
  buildInputs = [ alsa-lib ];

  # wgpu and winit dlopen these at runtime instead of linking them. Without
  # vulkan-loader the renderer finds no adapter and the window never opens.
  postFixup = ''
    wrapProgram $out/bin/moonglow \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libGL
          libxkbcommon
          vulkan-loader
          wayland
          libx11
          libxcursor
          libxi
          libxrandr
        ]
      }
  '';

  # The desktop entry, icons and module MIME type, named after the app ID so
  # the compositor matches the window to its icon.
  postInstall = ''
    id=io.github.moonglow_toolset.Moonglow
    install -Dm644 packaging/linux/$id.desktop -t $out/share/applications
    install -Dm644 packaging/linux/moonglow-mime.xml $out/share/mime/packages/$id.xml
    install -Dm644 packaging/icons/moonglow.svg $out/share/icons/hicolor/scalable/apps/$id.svg
    for s in 16 24 32 48 64 128 256 512; do
      install -Dm644 packaging/icons/moonglow-$s.png $out/share/icons/hicolor/''${s}x$s/apps/$id.png
    done
  '';

  meta = {
    description = "Native reimplementation of the Neverwinter Nights: Enhanced Edition Aurora Toolset";
    homepage = "https://github.com/jadzziaa/moonglow-toolset";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "moonglow";
  };
})
