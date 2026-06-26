{
  config,
  lib,
  options,
  ...
}:

let
  cfg = config.theorem.home.desktop.odysseus;
  hasHomePersistence = options.home ? persistence;

  homeDir = "${config.home.homeDirectory}";
  dataDir = "${homeDir}/${cfg.dataDirRelative}";
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
            "${homeDir}/Obsidian:/workspace/obsidian"
            "${homeDir}/Projects/odysseus-workspace/:/workspace/odysseus"
          ];

          environment = {
            OLLAMA_BASE_URL = cfg.ollamaUrl;
          };
        };
      };

      systemd.user.tmpfiles.rules = [
        # User tmpfiles has no authority to chown a rootless Podman volume after
        # the container maps it to a subuid. Keep activation from failing there.
        "d ${dataDir} 0700 - - -"
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
