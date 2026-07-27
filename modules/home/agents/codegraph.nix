{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.codegraph;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  version = "1.5.0";

  # Upstream ships a self-contained per-platform bundle (its own Node runtime
  # plus a native Rust parser kernel) as npm optionalDependencies, matching the
  # esbuild pattern. We fetch the one matching this host directly instead of
  # going through npm, then let autoPatchelfHook fix up the prebuilt ELF
  # binaries for the Nix store.
  platforms = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@colbymchenry/codegraph-linux-x64/-/codegraph-linux-x64-${version}.tgz";
      hash = "sha256-ZQFSDvM3LrdO5KhTfYsu5jyz2VU2+O3oUOdF6wam0aI=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@colbymchenry/codegraph-linux-arm64/-/codegraph-linux-arm64-${version}.tgz";
      hash = "sha256-8OnVbt4jQXe0/1pXe64bpZSORx9jxEk6eaA/TO6ZClA=";
    };
  };

  platform =
    platforms.${pkgs.stdenv.hostPlatform.system}
      or (throw "theorem.home.agents.codegraph: unsupported platform ${pkgs.stdenv.hostPlatform.system}");

  codegraphPackage = pkgs.stdenv.mkDerivation {
    pname = "codegraph";
    inherit version;

    src = pkgs.fetchurl { inherit (platform) url hash; };
    sourceRoot = "package";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/codegraph"
      cp -r . "$out/lib/codegraph"

      makeWrapper "$out/lib/codegraph/bin/codegraph" "$out/bin/codegraph" \
        --set CODEGRAPH_NO_UPDATE_CHECK 1

      runHook postInstall
    '';

    meta = {
      description = "Local-first code knowledge graph MCP server for AI coding agents";
      homepage = "https://github.com/colbymchenry/codegraph";
      mainProgram = "codegraph";
      platforms = builtins.attrNames platforms;
    };
  };
in
{
  options.theorem.home.agents.codegraph = {
    enable = lib.mkEnableOption "CodeGraph code knowledge graph MCP server";

    package = lib.mkOption {
      type = lib.types.package;
      default = codegraphPackage;
      defaultText = lib.literalExpression "theorem.home.agents.codegraph prebuilt bundle";
      description = ''
        CodeGraph CLI package to install. Defaults to a Nix-fetched copy of
        upstream's prebuilt platform bundle, patchelf'd for the Nix store.
        `CODEGRAPH_NO_UPDATE_CHECK` is set because Nix owns the version here;
        bump `version` in this module to upgrade instead of `codegraph upgrade`.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist `~/.codegraph` (beta-signup state and cached update-check
        results) when Home persistence is active.

        This module is package-only. Run `codegraph install` yourself to wire
        agents (it edits `~/.claude.json` / `~/.claude/settings.json` etc.)
        and `codegraph init` per project to build its index.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".codegraph"
        ];
      };
    })
  ];
}
