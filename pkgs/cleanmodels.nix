{
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  lib,
  makeDesktopItem,
  makeWrapper,
  libGL,
  qt6,
  stdenv,
  swi-prolog,
  symlinkJoin,
}:

let
  cleanmodels = stdenv.mkDerivation rec {
    pname = "cleanmodels";
    version = "4.0.0-rc6";

    src = fetchFromGitHub {
      name = "cleanmodels";
      owner = "plenarius";
      repo = "cleanmodels";
      rev = "v${version}";
      hash = "sha256-S0/QMFLECUGmwXVZI78uMVgFLgykGTQWFA6eXFukNSA=";
    };

    nativeBuildInputs = [
      makeWrapper
    ];

    buildInputs = [
      swi-prolog
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/cleanmodels
      cp -r ./* $out/share/cleanmodels/

      makeWrapper ${swi-prolog}/bin/swipl $out/bin/cleanmodels \
        --add-flags "-q" \
        --add-flags "-s $out/share/cleanmodels/cleanmodels.pl" \
        --add-flags "-g go" \
        --add-flags "-t halt" \
        --add-flags "--"

      ln -s $out/bin/cleanmodels $out/bin/cleanmodels-cli

      runHook postInstall
    '';

    meta = {
      description = "Clean and fix NWN:EE MDL model files";
      homepage = "https://github.com/plenarius/cleanmodels";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "cleanmodels";
    };
  };

  cleanmodels-qt = stdenv.mkDerivation rec {
    pname = "cleanmodels-qt";
    version = "1.0.0-rc4";

    src = fetchFromGitHub {
      name = "cleanmodels-qt";
      owner = "plenarius";
      repo = "cleanmodels-qt";
      # Pinned by commit, not by tag. Upstream force-moved `v1.0.0-rc4` onto a
      # Qt6 rewrite and rewrote the branch history, which broke every host that
      # had not already cached the old source. A commit cannot move.
      rev = "33b63b7b68fe2af92b00e6e4d8016b8596c91e70";
      hash = "sha256-kXd+bo3/17vlj1oFjt4JJi0BC1PCfaVlnMpTRPFS+WA=";
    };

    nativeBuildInputs = [
      cmake
      qt6.wrapQtAppsHook
      copyDesktopItems
    ];

    buildInputs = [
      libGL
      qt6.qtbase
    ];

    # Upstream leans on <QMatrix4x4> to drag in QQuaternion. Qt 6.11 stopped
    # doing that, so the header needs the include spelled out. Drop this once
    # upstream adds it.
    postPatch = ''
      sed -i '/#include <QMatrix4x4>/a #include <QQuaternion>' mdlanimationplayer.h
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "cleanmodels-qt";
        desktopName = "Clean Models:EE";
        genericName = "NWN:EE MDL Cleaner";
        comment = "Clean and fix Neverwinter Nights: Enhanced Edition MDL model files";
        exec = "cleanmodels-qt";
        icon = "cleanmodels-qt";
        terminal = false;
        categories = [
          "Development"
          "Graphics"
          "Utility"
        ];
      })
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 cleanmodels-qt $out/bin/cleanmodels-qt

      ln -s ${cleanmodels}/bin/cleanmodels-cli $out/bin/cleanmodels-cli

      runHook postInstall
    '';

    preFixup = ''
      qtWrapperArgs+=(
        --prefix PATH : ${lib.makeBinPath [ cleanmodels ]}
      )
    '';

    meta = {
      description = "Qt frontend for cleanmodels";
      homepage = "https://github.com/plenarius/cleanmodels-qt";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "cleanmodels-qt";
    };
  };
in
symlinkJoin {
  name = "cleanmodels-suite";

  paths = [
    cleanmodels
    cleanmodels-qt
  ];

  meta = {
    description = "Clean Models:EE Qt frontend with CLI";
    mainProgram = "cleanmodels-qt";
  };
}
