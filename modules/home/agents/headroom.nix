{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.headroom;
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
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
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
      description = "Optional env file containing API keys.";
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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      (pkgs.writeShellApplication {
        name = "headroom-env";
        text = ''
          export HEADROOM_BASE_URL="http://${cfg.host}:${toString cfg.port}"
          export OPENAI_BASE_URL="http://${cfg.host}:${toString cfg.port}/v1"
          export ANTHROPIC_BASE_URL="http://${cfg.host}:${toString cfg.port}"

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

    home.sessionVariables = lib.mkIf cfg.setClaudeAndCodexEnv {
      HEADROOM_BASE_URL = "http://${cfg.host}:${toString cfg.port}";
      OPENAI_BASE_URL = "http://${cfg.host}:${toString cfg.port}/v1";
      ANTHROPIC_BASE_URL = "http://${cfg.host}:${toString cfg.port}";
    };

    systemd.user.sessionVariables = lib.mkIf cfg.setClaudeAndCodexEnv {
      HEADROOM_BASE_URL = "http://${cfg.host}:${toString cfg.port}";
      OPENAI_BASE_URL = "http://${cfg.host}:${toString cfg.port}/v1";
      ANTHROPIC_BASE_URL = "http://${cfg.host}:${toString cfg.port}";
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
