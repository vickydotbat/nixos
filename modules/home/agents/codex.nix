{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.codex;

  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  codexNightlyPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex-nightly";
    version = "999.0.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -d "$out/bin"
      cat > "$out/bin/codex" <<'EOF'
      #!${pkgs.runtimeShell}
      set -euo pipefail

      flake_ref=${lib.escapeShellArg cfg.nightly.flakeRef}
      nix_command=${lib.escapeShellArg "${pkgs.nix}/bin/nix"}
      nix_args=(
        --extra-experimental-features
        'nix-command flakes'
      )

      ${lib.optionalString cfg.nightly.refreshOnRun ''
        if ! "$nix_command" "''${nix_args[@]}" flake metadata --refresh "$flake_ref" >/dev/null; then
          printf '%s\n' "codex nightly refresh failed; using cached flake if available: $flake_ref" >&2
        fi
      ''}

      exec "$nix_command" "''${nix_args[@]}" run "$flake_ref" -- "$@"
      EOF
      chmod +x "$out/bin/codex"

      runHook postInstall
    '';

    meta = {
      description = "Self-refreshing Codex nightly wrapper";
      homepage = "https://github.com/sadjow/codex-cli-nix";
      mainProgram = "codex";
    };

  };

  # The official "complete package" layout: bin/, codex-resources/, codex-path/
  # and codex-package.json side by side. Codex 0.157+ refuses to start its
  # app-server daemon without it, and the nightly flake ships only bin/codex.
  # The binaries are static musl, so they run unpatched; dontFixup keeps Nix
  # from stripping or rewriting them.
  #
  # 0.159.0-alpha.4 is pinned because it carries openai/codex#47968, the fix
  # for Btrfs subvolume device IDs that break sandbox socket isolation on this
  # impermanence layout. Move to a stable tag once one contains that fix.
  codexReleasePackage = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "codex";
    version = "0.159.0-alpha.4";

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-S89DC+IAXmkBUAhfaCpn5elDP3snsczRzxWZQO49JjU=";
    };

    sourceRoot = ".";
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r bin codex-resources codex-path codex-package.json "$out/"
      runHook postInstall
    '';

    meta = {
      description = "Official Codex CLI release package";
      homepage = "https://github.com/openai/codex";
      mainProgram = "codex";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  options.theorem.home.agents.codex = {
    enable = lib.mkEnableOption "Codex CLI";

    nightly = {
      flakeRef = lib.mkOption {
        type = lib.types.str;
        default = "github:sadjow/codex-cli-nix";
        description = ''
          Flake reference used by the default Codex nightly wrapper. Keep this
          as a moving reference when Codex should track upstream builds without
          teaching the system `flake.lock` to carry that churn.
        '';
      };

      refreshOnRun = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Refresh the Codex nightly flake before each `codex` invocation. When
          the network or Nix daemon is unavailable, the wrapper warns and then
          tries the cached flake output so Codex can still open.
        '';
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = codexReleasePackage;
      defaultText = lib.literalExpression "theorem.home.agents.codex pinned official release package";
      description = ''
        Codex CLI package to install. Defaults to the pinned official release
        package. The self-refreshing wrapper around `nightly.flakeRef` is kept
        for when that flake ships the complete package layout again.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist the full `~/.codex` directory when Home persistence is active.

        This module intentionally does not manage files inside `~/.codex`.
        Skills, rules, commands, config files, and AGENTS.md should be managed
        by a dedicated skills/config module or left as persistent mutable state.
      '';
    };

  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(config.programs.codex.enable or false);
          message = ''
            theorem.home.agents.codex is package-only and expects ~/.codex to be
            persistent or managed elsewhere. Do not enable programs.codex at the
            same time, because it may manage ~/.codex files and collide with
            skill/config installation.
          '';
        }
      ];

      home.packages = [
        cfg.package
      ];
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".codex"
        ];
      };
    })
  ];
}
