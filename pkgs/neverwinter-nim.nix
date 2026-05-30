{
  lib,
  config,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  sqlite,
  zlib,
  openssl,
}:

let
  platform =
    {
      x86_64-linux = {
        name = "x86_64-linux-gnu";
        hash = "sha256-+cwuUPvm91CVTRG4JENKkrEpE8wKNELpXcxe79Tdw4c=";
      };

      aarch64-linux = {
        name = "aarch64-linux-gnu";
        hash = "sha256-Clb3HXhexybrsUDZ9YfzQtGXH3X5TYB/pABDXEJbyQI=";
      };
    }.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in

stdenv.mkDerivation rec {
  pname = "neverwinter-nim-bin";
  version = "2.1.2";

  src = fetchurl {
    url = "https://github.com/niv/neverwinter.nim/releases/download/${version}/neverwinter-${platform.name}.zip";
    hash = platform.hash;
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    sqlite
    zlib
    openssl
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    find . -type f -name 'nwn_*' -exec cp {} $out/bin/ \;
    chmod +x $out/bin/nwn_*

    find . -type f -name '*.so*' -exec cp {} $out/lib/ \; || true

    for exe in $out/bin/nwn_*; do
      wrapProgram "$exe" \
        --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath [
          sqlite
          zlib
          openssl
          stdenv.cc.cc.lib
        ]}"
    done

    runHook postInstall
  '';

  meta = {
    description = "Neverwinter Nights: Enhanced Edition data accessor library and utilities";
    homepage = "https://github.com/niv/neverwinter.nim";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}