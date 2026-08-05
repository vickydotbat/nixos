{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "dcg";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "destructive_command_guard";
    rev = "v${version}";
    hash = "sha256-+Gcb/NYvLTWthIA8Q7iMa1yf/r5Q7otGaOmjcEs6tDs=";
  };

  cargoHash = "sha256-e6e6eRxj1d2DrzKzfIfW6XAOGNOkhCY1mFeAlFBFZF0=";

  # Upstream tests shell out to git and inspect terminal-shaped output, both
  # of which misbehave inside the build sandbox.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/dcg" --version
  '';

  meta = {
    description = "Hook that blocks destructive shell commands before a coding agent runs them";
    homepage = "https://github.com/Dicklesworthstone/destructive_command_guard";
    license = lib.licenses.mit;
    mainProgram = "dcg";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
