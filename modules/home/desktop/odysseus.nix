{
  config,
  lib,
  options,
  ...
}:

let
  cfg = config.theorem.home.desktop.odysseus;
  hasHomePersistence = options.home ? persistence;

  dataDir = "${config.home.homeDirectory}/${cfg.dataDirRelative}";
in
{
  options.theorem.home.desktop.odysseus = {
    enable = lib.mkEnableOption "Odysseus AI workspace";

    port = lib.mkOption {
      type = lib.types.port;
      default = 7000;
      description = "Local port for the Odysseus web UI.";
    };

    dataDirRelative = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/odysseus";
      description = ''
        Home-relative persistent Odysseus data directory. This is used both for
        the container volume and for Home Manager persistence.
      '';
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama URL visible from Odysseus.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(lib.hasPrefix "/" cfg.dataDirRelative);
          message = "theorem.home.desktop.odysseus.dataDirRelative must be home-relative, not absolute.";
        }
      ];

      services.podman = {
        enable = true;

        containers.odysseus = {
          image = "ghcr.io/pewdiepie-archdaemon/odysseus:latest";

          autoStart = true;

          # Host networking lets the container reach the user's Ollama service
          # at 127.0.0.1:11434.
          network = "host";

          volumes = [
            "${dataDir}:/app/data"
          ];

          environment = {
            OLLAMA_BASE_URL = cfg.ollamaUrl;
          };
        };
      };

      systemd.user.tmpfiles.rules = [
        "d ${dataDir} 0700 ${config.home.username} users -"
      ];
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              cfg.dataDirRelative
            ];
          };
    })
  ];
}
