{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.codex;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  system = pkgs.stdenv.hostPlatform.system;
  toml = pkgs.formats.toml { };
  initialConfigFile = toml.generate "codex-config.toml" cfg.initialConfig.settings;
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
    home.packages = [
      cfg.package
    ];

    home.persistence."/nix/persist" = lib.mkIf cfg.persistState {
      directories = [
        ".codex"
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
