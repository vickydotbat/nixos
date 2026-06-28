{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.opencode;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  watchdogScript = ../../../scripts/opencode-watchdog;
  jsonFormat = pkgs.formats.json { };
  safetyConfigPath = "${config.xdg.configHome}/opencode/safety.json";

  opencodeProviderConfig =
    lib.optionalAttrs (cfg.safeConfig.modelIds != [ ]) {
      whitelist = cfg.safeConfig.modelIds;
    }
    // lib.optionalAttrs (cfg.safeConfig.models != { }) {
      models = cfg.safeConfig.models;
    };

  opencodeSafetyConfig = {
    "$schema" = "https://opencode.ai/config.json";
    permission = cfg.safeConfig.permission;
    agent = cfg.safeConfig.agents;
  }
  // lib.optionalAttrs (cfg.safeConfig.providerId != null) {
    provider = {
      ${cfg.safeConfig.providerId} = opencodeProviderConfig;
    };
  }
  // lib.optionalAttrs (cfg.safeConfig.defaultModel != null && cfg.safeConfig.providerId != null) {
    model = "${cfg.safeConfig.providerId}/${cfg.safeConfig.defaultModel}";
  }
  // lib.optionalAttrs (cfg.safeConfig.smallModel != null && cfg.safeConfig.providerId != null) {
    small_model = "${cfg.safeConfig.providerId}/${cfg.safeConfig.smallModel}";
  };
in
{
  options.theorem.home.agents.opencode = {
    enable = lib.mkEnableOption "OpenCode terminal AI agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.opencode;
      defaultText = lib.literalExpression "pkgs.opencode";
      description = "OpenCode package to install.";
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist OpenCode configuration under `~/.config/opencode` when Home
        persistence is available. Disable this on hosts where the agent should
        begin with a blank configuration after each reboot.
      '';
    };

    installWatchdog = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install `opencode-watchdog`, a conservative wrapper that aborts an
        OpenCode process when model output resembles token-stream corruption.
      '';
    };

    safeConfig = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Write an OpenCode safety overlay and export `OPENCODE_CONFIG` so it
          merges over the normal user config. This keeps provider credentials
          and existing plugin setup outside Nix while declaring model routing,
          permissions, and bounded worker agents here.
        '';
      };

      providerId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "ollama-cloud";
        description = "Optional provider ID for model defaults and model metadata overrides.";
      };

      modelIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Optional provider model whitelist.";
      };

      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional default model ID under `safeConfig.providerId`.";
      };

      smallModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional small model ID under `safeConfig.providerId`.";
      };

      models = lib.mkOption {
        type = lib.types.attrsOf jsonFormat.type;
        default = { };
        description = ''
          Optional OpenCode model metadata, including explicit
          `limit.{context,input,output}` declarations.
        '';
      };

      permission = lib.mkOption {
        type = jsonFormat.type;
        default = {
          read = "allow";
          glob = "allow";
          grep = "allow";
          list = "allow";
          edit = "ask";
          task = "ask";
          todowrite = "ask";
          webfetch = "ask";
          websearch = "ask";
          external_directory = "ask";

          ".sops/**" = "deny";
          "**/.sops/**" = "deny";
          "*.sops.*" = "deny";
          "secrets/**" = "deny";
          "/run/secrets/**" = "deny";
          "/run/agenix/**" = "deny";
          "~/.ssh/**" = "deny";
          "~/.config/opencode/auth*" = "deny";

          bash = {
            "git status*" = "allow";
            "git diff*" = "allow";
            "git show*" = "allow";
            "git log*" = "allow";
            "git branch --show-current*" = "allow";
            "rg *" = "allow";
            "sed -n *" = "allow";
            "ls *" = "allow";
            "find *" = "allow";
            "nix eval *" = "allow";
            "nixfmt --check *" = "allow";
            "nix flake check*" = "ask";
            "nixos-rebuild *" = "ask";
            "home-manager *" = "ask";
            "mv *" = "ask";
            "chmod *" = "ask";
            "chown *" = "ask";
            "git commit*" = "ask";
            "git push*" = "deny";
            "git reset --hard*" = "deny";
            "git clean*" = "deny";
            "rm -rf *" = "deny";
            "rm -fr *" = "deny";
            "sudo *" = "ask";
            "run0 *" = "ask";
            "* .sops/*" = "deny";
            "* .sops/**" = "deny";
            "* *.sops.*" = "deny";
            "* secrets/*" = "deny";
            "* /run/secrets/*" = "deny";
            "* /run/agenix/*" = "deny";
            "* ~/.ssh/*" = "deny";
            "* ~/.config/opencode/auth*" = "deny";
          };
        };
        description = ''
          OpenCode permissions for the safety overlay. Defaults allow
          repository discovery, ask before edits or heavier commands, and deny
          destructive Git, destructive shell, and common secret paths.
        '';
      };

      agents = lib.mkOption {
        type = lib.types.attrsOf jsonFormat.type;
        default = { };
        description = ''
          OpenCode agent definitions for the safety overlay. Use this to keep
          unstable models in bounded worker roles with stricter permissions
          than supervisor and reviewer agents.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ]
      ++ lib.optional cfg.installWatchdog (
        pkgs.writeShellApplication {
          name = "opencode-watchdog";
          runtimeInputs = [
            pkgs.git
            pkgs.python3
          ];
          text = ''
            exec ${pkgs.python3}/bin/python3 ${watchdogScript} "$@"
          '';
        }
      );
    })

    (lib.mkIf (cfg.enable && cfg.safeConfig.enable) {
      home.sessionVariables.OPENCODE_CONFIG = safetyConfigPath;
      systemd.user.sessionVariables.OPENCODE_CONFIG = safetyConfigPath;

      xdg.configFile."opencode/safety.json" = {
        source = jsonFormat.generate "opencode-safety.json" opencodeSafetyConfig;
      };
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
        directories = [
          ".local/share/opencode"
          ".config/opencode"
        ];
      };
    })
  ];
}
