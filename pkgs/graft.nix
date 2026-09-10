{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  python3,
}:

buildNpmPackage rec {
  pname = "graft";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "trailhq";
    repo = "Graft";
    rev = "v${version}";
    hash = "sha256-NEPDkNn288B4TkGwa3E8jBP4YfxeXt2INWVK0DcGjhU=";
  };

  npmDepsHash = "sha256-e9/GBIEXv4IDQdbKj1I8erd8H0VRxMyfj7xjZ+o4WFo=";

  # tree-sitter ships native bindings; node-gyp needs python at build time.
  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  # Upstream bakes the absolute install path of the running graft into the
  # Claude Code shims that `graft init` writes into a repo. Those files are
  # meant to be committed, and a store path is both machine-local and
  # stale after the next rebuild. Read the location from GRAFT_DIST instead;
  # the wrapper below and the home module both set it.
  postPatch = ''
    substituteInPlace src/claude/shim-template.ts \
      --replace-fail 'const BAKED = ''${JSON.stringify(bakedDir)};' \
                     'const BAKED = process.env.GRAFT_DIST || "";'
  '';

  # Rebuild only the native grammar bindings graft imports. A blanket
  # `npm rebuild` also runs tree-sitter-cli's install script, which downloads a
  # binary from GitHub and fails in the sandbox. That CLI is a dev dependency
  # for generating grammars, and graft's build does not use it.
  npmRebuildFlags = [
    "tree-sitter"
    "tree-sitter-go"
    "tree-sitter-java"
    "tree-sitter-kotlin"
    "tree-sitter-php"
    "tree-sitter-python"
    "tree-sitter-swift"
    "tree-sitter-typescript"
    "@davisvaughan/tree-sitter-r"
  ];

  # Telemetry: a source build carries no PostHog key, but graft also honours
  # DO_NOT_TRACK, so set it and stop guessing.
  postInstall = ''
    wrapProgram "$out/bin/graft" \
      --set DO_NOT_TRACK 1 \
      --set GRAFT_DIST "$out/lib/node_modules/@nanonets/graft/dist/claude"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/graft" --version
  '';

  meta = {
    description = "Context graph of a codebase, as linked markdown files, for coding agents";
    homepage = "https://github.com/trailhq/Graft";
    license = lib.licenses.mit;
    mainProgram = "graft";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
