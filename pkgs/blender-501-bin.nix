{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  autoPatchelfHook,

  alsa-lib,
  dbus,
  expat,
  fontconfig,
  freetype,
  glib,
  libGL,
  libGLU,
  libX11,
  libXcursor,
  libXi,
  libXinerama,
  libXrandr,
  libXrender,
  libdecor,
  libdrm,
  libglvnd,
  libpulseaudio,
  libxkbcommon,
  wayland,

  # renamed non-xorg package names
  libxcb,
  libxext,
  libxfixes,
  libxshmfence,
  libSM,
  libICE,
  libXxf86vm,
  libXt,

  # missing runtime deps
  level-zero,
  zstd,
  libxcrypt-legacy,
  ncurses,

  # compatibility
  addDriverRunpath,
  vulkan-loader,
}:

stdenv.mkDerivation rec {
  pname = "blender-bin";
  version = "5.0.1";

  # majorMinor drives the release directory, the scripts path and the wrapper
  # name, so a future bump only needs `version` + `hash`.
  seriesDir = lib.versions.majorMinor version;
  binName = "blender-${version}";

  src = fetchurl {
    url = "https://download.blender.org/release/Blender${seriesDir}/blender-${version}-linux-x64.tar.xz";
    hash = "sha256-gBlYDuG3Ji5QX0GWoAI3zPdDyI0gWzjTQgFRBnbmCwk=";
  };

  # OpenImageDenoise ships CUDA/HIP device backends that dlopen driver libs at
  # runtime (found via /run/opengl-driver/lib). They are not present at build.
  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libamdhip64.so.6"
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
    addDriverRunpath
  ];

  buildInputs = [
    alsa-lib
    dbus
    expat
    fontconfig
    freetype
    glib
    libGL
    libGLU
    libX11
    libXcursor
    libXi
    libXinerama
    libXrandr
    libXrender
    libdecor
    libdrm
    libglvnd
    libpulseaudio
    libxkbcommon
    wayland

    libxcb
    libxext
    libxfixes
    libxshmfence
    libSM
    libICE
    libXxf86vm
    libXt

    level-zero
    zstd
    libxcrypt-legacy
    ncurses

    vulkan-loader
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/blender-${version}
    cp -r ./* $out/opt/blender-${version}/

    rm -rf $out/opt/blender-${version}/lib/mesa

    mkdir -p $out/bin

    makeWrapper $out/opt/blender-${version}/blender $out/bin/${binName} \
      --set BLENDER_SYSTEM_SCRIPTS $out/opt/blender-${version}/${seriesDir}/scripts \
      --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib:${
        lib.makeLibraryPath [
          libGL
          libGLU
          libglvnd
          vulkan-loader
          wayland
          libxkbcommon
        ]
      }"

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $out/opt/blender-${version}/blender.svg \
      $out/share/icons/hicolor/scalable/apps/${binName}.svg

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = binName;
      desktopName = "Blender ${version}";
      genericName = "3D Modeler";
      comment = "3D modeling, animation, rendering and post-production";
      exec = "${binName} %f";
      icon = binName;
      terminal = false;
      categories = [
        "Graphics"
        "3DGraphics"
      ];
      mimeTypes = [
        "application/x-blender"
      ];
      startupNotify = true;
    })
  ];

  meta = {
    description = "Official Blender ${version} binary tarball";
    homepage = "https://www.blender.org";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = binName;
  };
}
