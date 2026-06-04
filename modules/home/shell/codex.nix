{
  config,
  inputs,
  lib,
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
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  system = pkgs.stdenv.hostPlatform.system;
  toml = pkgs.formats.toml { };
  initialConfigFile = toml.generate "codex-config.toml" cfg.initialConfig.settings;
  superpowersSkills = lib.mapAttrs (
    name: _type: lib.mkDefault (cfg.superpowers.source + "/${name}")
  ) (builtins.readDir cfg.superpowers.source);
in
{
  options.theorem.home.shell.codex = {
    enable = lib.mkEnableOption "Codex CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.codex-cli-nix.packages.${system}.default;
      defaultText = lib.literalExpression "inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default";
      description = ''
        Codex CLI package to install. Defaults to the native binary from the
        `codex-cli-nix` flake; user modules may choose `codex-node` or another
        package when the native binary is not the right tool.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist Codex state when Home persistence is active.";
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

  config = lib.mkIf cfg.enable {
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
        cfg.context
      ];

      rules = lib.mkMerge [
        (lib.mkIf cfg.defaultRules.enable {
          default = lib.mkDefault ''
            prefix_rule(pattern = ["nix", "flake", "check"], decision = "allow")
            prefix_rule(pattern = ["nix", "eval"], decision = "allow")
            prefix_rule(pattern = ["nix", "fmt"], decision = "allow")
            prefix_rule(pattern = ["git", "status"], decision = "allow")
            prefix_rule(pattern = ["git", "diff"], decision = "allow")
          '';
        })
        cfg.rules
      ];

      skills = lib.mkMerge [
        (lib.mkIf cfg.superpowers.enable superpowersSkills)
        cfg.skills
      ];
    };

    home.persistence."/nix/persist" = lib.mkIf cfg.persistState {
      directories = [
        ".codex" # TODO: Confirm whether persisting this is a good idea. Codex might prefer a clean slate on each launch, especially since we generate the settings and context.
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
  };
}
