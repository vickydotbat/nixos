{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "rtk";
  version = "0.44.2";

  src = fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-qOWWHov0m3A8V48r/UGN2Hxz+/XraPRYhNPnZ+B+ZBY=";
  };

  cargoHash = "sha256-1nuCXZZjGDyA8kN6pFPclx8sIdD6QbGZDlTtyl+6Gow=";

  # Upstream tests shell out to the very tools rtk proxies (git, cargo, docker),
  # which are absent or non-deterministic inside the build sandbox.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/rtk" --version
  '';

  meta = {
    description = "CLI proxy that filters noisy dev-command output to cut LLM token use";
    homepage = "https://github.com/rtk-ai/rtk";
    license = lib.licenses.asl20;
    mainProgram = "rtk";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
