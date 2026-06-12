{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  git,
}:

rustPlatform.buildRustPackage rec {
  pname = "fallow";
  version = "2.94.0";

  src = fetchFromGitHub {
    owner = "fallow-rs";
    repo = "fallow";
    rev = "v${version}";

    # Run once with this fake hash, then replace with the hash Nix prints.
    hash = "sha256-A2uKtyJ7Gfzp9R6Z+HMTWpxuUM6VSuHbRzUXFgotFlo=";
  };

  # Run again after fixing src.hash, then replace with the cargoHash Nix prints.
  cargoHash = "sha256-5wLMA/YGp0tGU3iCNKTBkNT/OfwjwGNAixXEuwNqO98=";

  # The repository is a workspace; build only the CLI crate.
  cargoBuildFlags = [
    "-p"
    "fallow-cli"
  ];

  cargoTestFlags = cargoBuildFlags;

  # Upstream workspace tests are broader than needed for a local CLI package.
  doCheck = false;

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    wrapProgram "$out/bin/fallow" \
      --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    FALLOW_UPDATE_CHECK=off "$out/bin/fallow" --version
  '';

  meta = {
    description = "Rust-native codebase intelligence for TypeScript and JavaScript";
    homepage = "https://github.com/fallow-rs/fallow";
    license = lib.licenses.mit;
    mainProgram = "fallow";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
