{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.headroom;

  jsonFormat = pkgs.formats.json { };

  headroomBaseUrl = "http://${cfg.host}:${toString cfg.port}";
  headroomOpenAIBaseUrl = "${headroomBaseUrl}/v1";

  opencodeProviderConfig =
    lib.optionalAttrs (cfg.opencode.ollamaCloudModelIds != [ ]) {
      # OpenCode supports whitelist/blacklist on providers.
      # This hides every Ollama Cloud model except the ones listed here.
      whitelist = cfg.opencode.ollamaCloudModelIds;
    }
    // lib.optionalAttrs (cfg.opencode.ollamaCloudModels != { }) {
      # Optional metadata/overrides for models.
      # Not required if OpenCode already knows the model through Models.dev.
      models = cfg.opencode.ollamaCloudModels;
    };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";

    provider = {
      ${cfg.opencode.providerId} = opencodeProviderConfig;
    };
  }
  // lib.optionalAttrs (cfg.opencode.defaultModel != null) {
    model = "${cfg.opencode.providerId}/${cfg.opencode.defaultModel}";
  }
  // lib.optionalAttrs (cfg.opencode.smallModel != null) {
    small_model = "${cfg.opencode.providerId}/${cfg.opencode.smallModel}";
  };
in
{
  options.theorem.home.agents.headroom = {
    enable = lib.mkEnableOption "Headroom local proxy";

    package = lib.mkOption {
      type = lib.types.package;

      default = pkgs.python313Packages.buildPythonApplication rec {
        pname = "headroom-ai";
        version = "0.5.23";
        pyproject = true;

        src = pkgs.fetchPypi {
          pname = "headroom_ai";
          inherit version;
          hash = "sha256-Clu4d73Zg01saJdHRe+920eRgzZFnP5ReWU4snh1gmE=";
        };

        nativeBuildInputs = with pkgs.python313Packages; [
          hatchling
          pythonRelaxDepsHook
        ];

        pythonRelaxDeps = [
          "litellm"
        ];

        propagatedBuildInputs = with pkgs.python313Packages; [
          fastapi
          uvicorn
          httpx
          pydantic
          h2
          python-dotenv
          rich
          typer

          litellm
          opentelemetry-api
          tiktoken
        ];

        pythonImportsCheck = [ "headroom" ];

        meta.mainProgram = "headroom";
      };

      description = "Headroom package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address for the Headroom proxy.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "Port for the Headroom proxy.";
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "token"
        "cache"
        "token_mode"
        "cache_mode"
        "token_savings"
        "cost_savings"
        "token_headroom"
      ];
      default = "token";
      description = ''
        Headroom proxy mode. Valid values are taken from the installed
        headroom proxy CLI.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/user/1000/secrets/headroom-env";
      description = "Optional env file containing API keys for the Headroom service.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to start Headroom with the user session.";
    };

    setClaudeAndCodexEnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Export OpenAI/Anthropic base URLs in the user session.";
    };

    opencode = {
      enable = lib.mkEnableOption "OpenCode Ollama Cloud config";

      providerId = lib.mkOption {
        type = lib.types.str;
        default = "ollama-cloud";
        description = ''
          OpenCode provider ID for Ollama Cloud.

          OpenCode / Models.dev currently use `ollama-cloud`.
        '';
      };

      ollamaCloudModelIds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "qwen3-coder:480b"
          "qwen3-coder-next"
          "kimi-k2.7-code"
          "gpt-oss:120b"
        ];
        description = ''
          Ollama Cloud model IDs to expose in OpenCode.

          If this list is empty, no whitelist is written and OpenCode may show
          all models available from the Ollama Cloud provider.

          Use the model IDs shown by OpenCode `/models` or Models.dev for the
          `ollama-cloud` provider.
        '';
      };

      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "qwen3-coder:480b";
        description = "Optional default OpenCode model ID under the Ollama Cloud provider.";
      };

      smallModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "gpt-oss:20b";
        description = "Optional OpenCode small_model ID under the Ollama Cloud provider.";
      };

      ollamaCloudModels = lib.mkOption {
        type = lib.types.attrsOf jsonFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            "qwen3-coder:480b" = {
              name = "Qwen3 Coder 480B";
              limit = {
                context = 262144;
                output = 65536;
              };
            };

            "kimi-k2.7-code" = {
              name = "Kimi K2.7 Code";
              limit = {
                context = 262144;
                output = 262144;
              };
            };
          }
        '';
        description = ''
          Optional model metadata/overrides for Ollama Cloud models.

          You usually do not need this unless you want clearer display names
          or explicit limits.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package

      (pkgs.writeShellApplication {
        name = "headroom-env";

        text = ''
          export HEADROOM_BASE_URL="${headroomBaseUrl}"
          export OPENAI_BASE_URL="${headroomOpenAIBaseUrl}"
          export ANTHROPIC_BASE_URL="${headroomBaseUrl}"

          if [ "$#" -eq 0 ]; then
            echo "HEADROOM_BASE_URL=$HEADROOM_BASE_URL"
            echo "OPENAI_BASE_URL=$OPENAI_BASE_URL"
            echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
            echo
            echo "Usage: headroom-env <command>"
            exit 0
          fi

          exec "$@"
        '';
      })
    ];

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf cfg.setClaudeAndCodexEnv {
        HEADROOM_BASE_URL = headroomBaseUrl;
        OPENAI_BASE_URL = headroomOpenAIBaseUrl;
        ANTHROPIC_BASE_URL = headroomBaseUrl;
      })

      (lib.mkIf cfg.opencode.enable {
        OPENCODE_CONFIG = "${config.xdg.configHome}/opencode/headroom.json";
      })
    ];

    systemd.user.sessionVariables = lib.mkMerge [
      (lib.mkIf cfg.setClaudeAndCodexEnv {
        HEADROOM_BASE_URL = headroomBaseUrl;
        OPENAI_BASE_URL = headroomOpenAIBaseUrl;
        ANTHROPIC_BASE_URL = headroomBaseUrl;
      })

      (lib.mkIf cfg.opencode.enable {
        OPENCODE_CONFIG = "${config.xdg.configHome}/opencode/headroom.json";
      })
    ];

    xdg.configFile."opencode/headroom.json" = lib.mkIf cfg.opencode.enable {
      source = jsonFormat.generate "opencode-headroom.json" opencodeConfig;
    };

    systemd.user.services.headroom = {
      Unit = {
        Description = "Headroom local AI proxy";
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} proxy --host ${cfg.host} --port ${toString cfg.port} --mode ${cfg.mode}";
        Restart = "on-failure";
        RestartSec = 3;
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };

      Install = lib.mkIf cfg.autoStart {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
