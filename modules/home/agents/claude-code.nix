{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.claude;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  claudeNightlyPackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "claude-nightly";
    version = "999.0.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -d "$out/bin"
      cat > "$out/bin/claude" <<'EOF'
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
          printf '%s\n' "claude nightly refresh failed; using cached flake if available: $flake_ref" >&2
        fi
      ''}

      exec "$nix_command" "''${nix_args[@]}" run "$flake_ref" -- "$@"
      EOF
      chmod +x "$out/bin/claude"

      runHook postInstall
    '';

    meta = {
      description = "Self-refreshing Claude nightly wrapper";
      homepage = "https://github.com/sadjow/claude-code-nix";
      mainProgram = "claude";
    };

  };
in
{
  options.theorem.home.agents.claude = {
    enable = lib.mkEnableOption "Claude Code terminal AI agent";

    nightly = {
      flakeRef = lib.mkOption {
        type = lib.types.str;
        default = "github:sadjow/claude-code-nix";
        description = ''
          Flake reference used by the default Claude nightly wrapper. Keep this
          as a moving reference when Claude should track upstream builds without
          teaching the system `flake.lock` to carry that churn.
        '';
      };

      refreshOnRun = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Refresh the Claude nightly flake before each `claude` invocation. When
          the network or Nix daemon is unavailable, the wrapper warns and then
          tries the cached flake output so Claude can still open.
        '';
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = claudeNightlyPackage;
      defaultText = lib.literalExpression "theorem.home.agents.claude nightly wrapper";
      description = ''
        Claude CLI package to install. Defaults to a self-refreshing wrapper
        around `nightly.flakeRef`.
      '';
    };

    useDevShell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Run `claude` inside the project's `nix develop` shell. A Bash function
        looks for a `flake.nix` at the top of the current git repository and,
        when that flake provides a default dev shell, starts Claude through
        `nix develop`, so the agent sees the same tools the project promises.
        Without a flake, or with a flake that has no default dev shell, it runs
        Claude directly.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist the full `~/.claude` directory when Home persistence is active.

        This module intentionally does not manage files inside `~/.claude`.
        Skills, rules, commands, config files, and AGENTS.md should be managed
        by a dedicated skills/config module or left as persistent mutable state.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(config.programs.claude.enable or false);
          message = ''
            theorem.home.agents.claude is package-only and expects ~/.claude to be
            persistent or managed elsewhere. Do not enable programs.claude at the
            same time, because it may manage ~/.claude files and collide with
            skill/config installation.
          '';
        }
      ];

      home.packages = [
        cfg.package
      ];

      # `nix develop --command` runs the binary straight from PATH, so the
      # function does not call itself.
      programs.bash.initExtra = lib.mkIf cfg.useDevShell ''
        claude() {
          local root
          root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"

          # A flake.nix is not a promise of a dev shell: a repo can ship a flake
          # with no devShells.default, and `nix develop` then fails outright.
          # Probe first, so such a repo still opens Claude. The probe builds the
          # shell, which the real call then takes from the cache.
          if [ -e "$root/flake.nix" ] \
            && nix develop "$root" --command true </dev/null >/dev/null 2>&1; then
            nix develop "$root" --command claude "$@"
          else
            command claude "$@"
          fi
        }
      '';
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".claude"
        ];
      };
    })
  ];
}
