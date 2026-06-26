{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.ollama;
  hasHomePersistence = options.home ? persistence;

  packageForAcceleration =
    if cfg.acceleration == "rocm" then
      pkgs.ollama-rocm
    else if cfg.acceleration == "cuda" then
      pkgs.ollama-cuda
    else
      pkgs.ollama;
in
{
  options.theorem.home.base.ollama = {
    enable = lib.mkEnableOption "Ollama";

    acceleration = lib.mkOption {
      type = lib.types.enum [
        "cpu"
        "rocm"
        "cuda"
      ];
      default = "cpu";
      description = ''
        Select which Ollama package to use for this host.
      '';
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Persist the user's ~/.ollama directory when home.persistence is available.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address for the Ollama server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port for the Ollama server.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.ollama = {
        enable = true;
        package = packageForAcceleration;

        environmentVariables = {
          OLLAMA_MAX_LOADED_MODELS = "1";
          OLLAMA_NUM_PARALLEL = "1";
          OLLAMA_KEEP_ALIVE = "5m";
          OLLAMA_CONTEXT_LENGTH = "8192";
        };

        host = cfg.host;
        port = cfg.port;
      };
    })

    (lib.mkIf (cfg.enable && cfg.persist && hasHomePersistence) {
      home.persistence."/nix/persist" = {
        directories = [
          ".ollama"
        ];
      };
    })
  ];
}
