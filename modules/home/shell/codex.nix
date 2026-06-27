{
  config,
  inputs,
  lib,
  options,
  pkgs,
  repository ? {
    path = "/nix/nixos";
  },
  ...
}:
# Codex CLI is operator tooling. This module installs the selected package,
# writes the reusable baseline config, and persists agent state only when the
# user's Home persistence theorem says that state should survive reboot.

let
  cfg = config.theorem.home.shell.codex;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  toml = pkgs.formats.toml { };
  initialConfigFile = toml.generate "codex-config.toml" cfg.initialConfig.settings;
  superpowersSkills = lib.mapAttrs (
    name: _type: lib.mkDefault (cfg.superpowers.source + "/${name}")
  ) (builtins.readDir cfg.superpowers.source);
  ponytailSkills = lib.mapAttrs (name: _type: lib.mkDefault (cfg.ponytail.source + "/${name}")) (
    builtins.readDir cfg.ponytail.source
  );
  cavemanSkills = lib.mapAttrs (name: _type: lib.mkDefault (cfg.caveman.source + "/${name}")) (
    builtins.readDir cfg.caveman.source
  );

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
in
{
  options.theorem.home.shell.codex = {
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
          tries the cached flake output so the repair bench can still open.
        '';
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = codexNightlyPackage;
      defaultText = lib.literalExpression "theorem.home.shell.codex nightly wrapper";
      description = ''
        Codex CLI package to install. Defaults to a self-refreshing wrapper
        around `nightly.flakeRef`, so nightly updates do not require this
        repository's `flake.lock` to move. User modules may choose `pkgs.codex`,
        `codex-node`, or another package when the live nightly is not the right
        tool.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist Codex state when Home persistence is active. Disable this when
        a host should force a clean agent slate on each boot; keep it enabled
        when login state, installed skills, or local approval memory are part of
        the operator's repair kit.
      '';
    };

    trustNixosConfiguration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Trust `repository.path` as a Codex project. Disable this on hosts where
        the configured flake repository is mounted for inspection only, or where
        trust should be granted by hand after checking the local worktree.
      '';
    };

    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = ''
        Additional Codex settings written to `~/.codex/config.toml`. The module
        provides conservative defaults with `mkDefault`; user profiles should
        set model choice, approval posture, and other personal doctrine here.
      '';
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Global Codex context written to `~/.codex/AGENTS.md`. Keep this short:
        repository doctrine belongs in project `AGENTS.md`, while this is the
        operator's portable field note.
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Codex rule files managed under `~/.codex/rules`. User profile values
        override the default allow-list when the same rule name is declared.
      '';
    };

    defaultRules.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install a small default Codex command allow-list for low-risk inspection
        and Nix validation commands. Disable when every recurring approval
        should be trained interactively instead.
      '';
    };

    superpowers = {
      enable = lib.mkEnableOption "Superpowers Codex skills";

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.superpowers + "/skills";
        defaultText = lib.literalExpression ''inputs.superpowers + "/skills"'';
        description = ''
          Directory containing Superpowers skill folders. Defaults to the
          pinned `superpowers` flake input so updates pass through `flake.lock`
          instead of an unmanaged `git pull`.
        '';
      };
    };

    ponytail = {
      enable = lib.mkEnableOption "Ponytail Codex skills";

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.ponytail + "/skills";
        defaultText = lib.literalExpression ''inputs.ponytail + "/skills"'';
        description = ''
          Directory containing Ponytail skill folders. Defaults to the
          pinned `ponytail` flake input so updates pass through `flake.lock`
          instead of an unmanaged `git pull`.
        '';
      };

      level = lib.mkOption {
        type = lib.types.enum [
          "lite"
          "full"
          "ultra"
          "off"
        ];
        default = "full";
        description = ''
          Default Ponytail mode for new Codex sessions.
        '';
      };
    };

    caveman = {
      enable = lib.mkEnableOption "Caveman Codex skill";

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.caveman + "/skills";
        defaultText = lib.literalExpression ''inputs.caveman + "/skills"'';
        description = ''
          Directory containing Caveman skill folders. Defaults to the pinned
          `caveman` flake input so updates pass through `flake.lock` instead
          of an unmanaged `git pull`.
        '';
      };

      level = lib.mkOption {
        type = lib.types.enum [
          "lite"
          "full"
          "ultra"
          "wenyan-lite"
          "wenyan-full"
          "wenyan-ultra"
          "off"
        ];
        default = "full";
        description = ''
          Default Caveman compression mode for new Codex sessions.
        '';
      };
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Additional Codex skills. These are merged with Superpowers when enabled;
        profile-defined skills win if a name collides, so local repair doctrine
        can overrule the imported kit.
      '';
    };

    initialConfig = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Seed `~/.codex/config.toml` only when it does not already exist. This
          is a first-spawn rite, not declarative ownership; rebuilds must not
          clobber live Codex configuration.
        '';
      };

      settings = lib.mkOption {
        type = toml.type;
        default = { };
        description = ''
          Initial Codex settings written only when `~/.codex/config.toml` is
          absent. Workflow policy, model choice, and sandbox posture are user
          doctrine and should be set from user modules.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.codex = {
        enable = true;
        package = cfg.package;

        settings = lib.mkMerge [
          {
            approval_policy = lib.mkDefault "on-request";
            sandbox_mode = lib.mkDefault "workspace-write";
            web_search = lib.mkDefault "cached";
            hide_agent_reasoning = lib.mkDefault true;

            history.persistence = lib.mkDefault "none";

            sandbox_workspace_write = {
              network_access = lib.mkDefault false;
              exclude_slash_tmp = lib.mkDefault true;
              exclude_tmpdir_env_var = lib.mkDefault true;
            };

            shell_environment_policy."inherit" = lib.mkDefault "core";
          }
          (lib.mkIf cfg.trustNixosConfiguration {
            projects.${repository.path}.trust_level = lib.mkDefault "trusted";
          })
          cfg.settings
        ];

        context = lib.mkMerge [
          (lib.mkDefault ''
            Prefer small, reviewable changes.
            Do not run destructive commands unless explicitly asked.
            For NixOS work, prefer `nix flake check`, targeted `nix eval`, and `nixos-rebuild dry-build` before switching.
          '')
          (lib.mkIf (cfg.context != "") cfg.context)
        ];

        rules = lib.mkMerge [
          (lib.mkIf cfg.defaultRules.enable {
            default = lib.mkDefault ''
              prefix_rule(pattern = ["nix", "flake", "check"], decision = "allow")
              prefix_rule(pattern = ["nix", "flake", "metadata"], decision = "allow")
              prefix_rule(pattern = ["nix", "flake", "show"], decision = "allow")
              prefix_rule(pattern = ["nix", "eval"], decision = "allow")
              prefix_rule(pattern = ["nixfmt", "--check"], decision = "allow")
              prefix_rule(pattern = ["git", "status"], decision = "allow")
              prefix_rule(pattern = ["git", "diff"], decision = "allow")
              prefix_rule(pattern = ["git", "log"], decision = "allow")
              prefix_rule(pattern = ["git", "show"], decision = "allow")
              prefix_rule(pattern = ["rg"], decision = "allow")
            '';
          })
          cfg.rules
        ];

        skills = lib.mkMerge [
          (lib.mkIf cfg.superpowers.enable superpowersSkills)
          (lib.mkIf cfg.ponytail.enable ponytailSkills)
          (lib.mkIf cfg.caveman.enable cavemanSkills)
          cfg.skills
        ];
      };

      home.activation.codexInitialConfig = lib.mkIf cfg.initialConfig.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          config_dir=${lib.escapeShellArg "${config.home.homeDirectory}/.codex"}
          config_file="$config_dir/config.toml"

          if [[ ! -e "$config_file" ]]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$config_dir"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 ${lib.escapeShellArg initialConfigFile} "$config_file"
          fi
        ''
      );

      home.sessionVariables = lib.mkMerge [
        (lib.mkIf cfg.ponytail.enable {
          PONYTAIL_DEFAULT_MODE = cfg.ponytail.level;
        })

        (lib.mkIf cfg.caveman.enable {
          CAVEMAN_DEFAULT_MODE = cfg.caveman.level;
        })
      ];

      xdg.configFile = {
        "ponytail/config.json" = lib.mkIf cfg.ponytail.enable {
          text = builtins.toJSON {
            defaultMode = cfg.ponytail.level;
          };
        };

        "caveman/config.json" = lib.mkIf cfg.caveman.enable {
          text = builtins.toJSON {
            defaultMode = cfg.caveman.level;
          };
        };
      };
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
