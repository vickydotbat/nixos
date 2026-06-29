{
  config,
  lib,
  options,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.pi;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  jsonFormat = pkgs.formats.json { };
  system = pkgs.stdenv.hostPlatform.system;
  homeDir = config.home.homeDirectory;

  ollamaBaseUrl =
    if cfg.ollama.baseUrl != null then
      cfg.ollama.baseUrl
    else
      "http://${cfg.ollama.host}:${toString cfg.ollama.port}";

  ollamaApiBaseUrl =
    if lib.hasSuffix "/v1" ollamaBaseUrl then
      ollamaBaseUrl
    else
      "${lib.removeSuffix "/" ollamaBaseUrl}/v1";

  ollamaModels = lib.optionalAttrs cfg.ollama.enable {
    providers = {
      ollama = {
        baseUrl = ollamaApiBaseUrl;
        api = "openai-completions";
        apiKey = "ollama";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = map (modelId: { id = modelId; }) cfg.ollama.models;
      };
    };
  };

  effectiveModels = lib.recursiveUpdate ollamaModels cfg.models;
  effectiveExtraEnv =
    cfg.extraEnv
    // lib.optionalAttrs cfg.ollama.enable {
      OLLAMA_HOST = ollamaBaseUrl;
      OLLAMA_BASE_URL = ollamaApiBaseUrl;
    };

  hasConfigPayload = effectiveModels != { } || cfg.keybindings != { };

  modelsJson = jsonFormat.generate "pi-models.json" effectiveModels;
  keybindingsJson = jsonFormat.generate "pi-keybindings.json" cfg.keybindings;

  piWrapper = pkgs.writeShellScript "pi-coding-agent-wrapper" ''
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "export ${name}=${lib.escapeShellArg (toString value)}"
      ) effectiveExtraEnv
    )}

    case "''${1-}" in
      install|remove|uninstall|update|list|config)
        exec ${cfg.package}/bin/pi "$@"
        ;;
    esac

    ${lib.optionalString (cfg.ollama.enable && cfg.ollama.defaultModel != null) ''
      has_model_selection=0
      for arg in "$@"; do
        case "$arg" in
          --provider|--provider=*|--model|--model=*|--models|--models=*)
            has_model_selection=1
            ;;
        esac
      done

      if [ "$has_model_selection" -eq 0 ]; then
        set -- --provider ollama --model ${lib.escapeShellArg cfg.ollama.defaultModel} "$@"
      fi
    ''}

    exec ${cfg.package}/bin/pi "$@"
  '';

  piPackage =
    if effectiveExtraEnv == { } && !(cfg.ollama.enable && cfg.ollama.defaultModel != null) then
      cfg.package
    else
      pkgs.symlinkJoin {
        name = "pi-coding-agent-wrapped";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          rm "$out/bin/pi"
          makeWrapper ${pkgs.bash}/bin/bash "$out/bin/pi" \
            --add-flags ${piWrapper}
        '';
      };
in
{
  options.theorem.home.agents.pi = {
    enable = lib.mkEnableOption "Pi Coding Agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.pi-flake.packages.${system}.default;
      defaultText = lib.literalExpression "inputs.pi-flake.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Pi Coding Agent package to install.";
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist Pi state under `~/.pi` when Home persistence is available.
        Disable this on hosts where the agent should forget mutable state after
        reboot.
      '';
    };

    manageConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Manage `~/.pi/agent/models.json` and `~/.pi/agent/keybindings.json`
        as declarative Home Manager files.

        The default leaves `~/.pi` mutable so Pi and other same-user agents can
        edit their own state without meeting read-only Nix store symlinks.
        Enable this only when those files should be repaired from Nix instead
        of edited in place.
      '';
    };

    seedConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Seed `~/.pi/agent/models.json` and `~/.pi/agent/keybindings.json`
        as ordinary mutable files when they are missing.

        This is the repairable middle path for agent workstations: Nix can lay
        down a known starting point, while Pi and same-user agents can still
        edit the files after first activation. Existing files are left in
        place.
      '';
    };

    models = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        Additional Pi `models.json` configuration.

        This is merged after generated provider entries such as
        `ollama.models`, so user profiles can override or extend generated
        provider configuration when the model forge needs finer calibration.

        Do not place API keys or tokens here; this file is generated through
        the Nix store. Reference runtime environment variables instead.
      '';
    };

    keybindings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Pi keybinding configuration written to `~/.pi/agent/keybindings.json`.";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.int);
      default = { };
      description = ''
        Non-secret environment variables wrapped around the `pi` executable.
        Values are embedded in the Nix store, so this must not carry tokens.
      '';
    };

    ollama = {
      enable = lib.mkEnableOption "Ollama support for Pi";

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Ollama host used by Pi's wrapper and generated model entries.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Ollama port used by Pi's wrapper and generated model entries.";
      };

      baseUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "http://127.0.0.1:11434";
        description = ''
          Explicit Ollama base URL. When unset, this is derived from
          `ollama.host` and `ollama.port`.
        '';
      };

      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "qwen3-coder:480b-cloud";
        description = ''
          Optional Ollama model to pass to Pi when the command line did not
          already select a provider or model.
        '';
      };

      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "qwen3-coder:480b-cloud"
          "gpt-oss:120b-cloud"
        ];
        description = ''
          Ollama model IDs to seed into Pi's `models.json`.

          These entries use Pi's current custom provider schema with the
          OpenAI-compatible Ollama endpoint at `/v1`. For Ollama Cloud models,
          keep the user's Ollama account authenticated outside Nix; do not
          place credentials here.
        '';
      };
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Reserved for future declarative Pi extension support.

        The upstream Pi Home Manager module installs extensions from activation,
        which can perform network work during `home-manager switch`. This shared
        theorem refuses that failure mode; keep this empty until extension
        installation has a non-activation mechanism.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.manageConfig && cfg.seedConfig);
          message = ''
            theorem.home.agents.pi.manageConfig and seedConfig are mutually
            exclusive. Use manageConfig for read-only repair from Nix, or
            seedConfig for editable first-run files.
          '';
        }
        {
          assertion = cfg.manageConfig || cfg.seedConfig || !hasConfigPayload;
          message = ''
            theorem.home.agents.pi has Pi model or keybinding data, but neither
            manageConfig nor seedConfig is enabled. Either let Nix manage the
            files, seed editable first-run files, or keep Pi config wholly
            mutable under ~/.pi.
          '';
        }
        {
          assertion = cfg.extensions == [ ];
          message = ''
            theorem.home.agents.pi.extensions is intentionally disabled because
            upstream Pi installs extensions during Home Manager activation.
            Keep activation free of network and package-install side effects.
          '';
        }
      ];

      home.packages = [
        piPackage
      ];

      systemd.user.tmpfiles.rules = [
        "d ${homeDir}/.pi 0700 - - -"
        "d ${homeDir}/.pi/agent 0700 - - -"
      ]
      ++ lib.optionals cfg.seedConfig [
        "C ${homeDir}/.pi/agent/models.json 0600 - - - ${modelsJson}"
        "C ${homeDir}/.pi/agent/keybindings.json 0600 - - - ${keybindingsJson}"
      ];

      home.file = lib.mkIf cfg.manageConfig {
        ".pi/agent/models.json".source = modelsJson;
        ".pi/agent/keybindings.json".source = keybindingsJson;
      };
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
        directories = [
          ".pi"
        ];
      };
    })
  ];
}
