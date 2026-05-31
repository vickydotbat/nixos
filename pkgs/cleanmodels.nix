{
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  lib,
  makeDesktopItem,
  makeWrapper,
  qt5,
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
      rev = "v${version}";
      hash = "sha256-pcvV1nrE16P821OIuC6P1p9PLQhGCOa+baGnMpdiZzo=";
    };

    nativeBuildInputs = [
      cmake
      qt5.wrapQtAppsHook
      copyDesktopItems
    ];

    buildInputs = [
      qt5.qtbase
    ];

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
