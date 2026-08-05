{
  config,
  osConfig ? null,
  lib,
  options,
  pkgs,
  ...
}:

# V Rising dedicated server, run as a rootless Podman container.
#
# The game server is a Windows binary; the Didstopia image carries SteamCMD
# plus Wine to run it on Linux. Nothing here is packaged in nixpkgs and the
# image updates itself from Steam on restart, so a container is the honest
# shape for it rather than a derivation.
#
# Two volumes, matching the upstream compose file:
#   <dataDir>/saves -> /app/vrising      config + world saves (small, precious)
#   <dataDir>/game  -> /steamcmd/vrising server install from Steam (~10 GB)
#
# Config lives in the saves volume as JSON. With defaultHostSettings /
# defaultGameSettings left false, the settings JSON is written once and then
# left alone, so hand edits survive restarts; the options below only seed it.
# Flip them to true to make the env vars authoritative on every boot.

let
  cfg = config.theorem.home.gaming.vrising;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);

  podmanEnabled =
    osConfig != null
    && (osConfig.virtualisation.containers.enable or false)
    && (osConfig.virtualisation.podman.enable or false);

  dataDir = "${config.home.homeDirectory}/${cfg.dataDir}";

  boolStr = b: if b then "true" else "false";

  environment = {
    V_RISING_SERVER_PERSISTENT_DATA_PATH = "/app/vrising";
    V_RISING_SERVER_BRANCH = "public";
    # 0 = validate against Steam then start, 2 = install once, then trust the
    # local copy. Mode 0 re-verifies ~2 GB on every boot, which turns a restart
    # into a ten-minute wait; mode 2 restarts in about a minute.
    V_RISING_SERVER_START_MODE = if cfg.updateOnStart then "0" else "2";
    # Independent of the above: the container keeps checking Steam in the
    # background and pulls a new build when one lands, so mode 2 does not mean
    # sitting on a version the clients have already moved past.
    V_RISING_SERVER_UPDATE_MODE = "1";

    V_RISING_SERVER_NAME = cfg.serverName;
    V_RISING_SERVER_DESCRIPTION = cfg.description;
    V_RISING_SERVER_SAVE_NAME = cfg.saveName;
    V_RISING_SERVER_PASSWORD = cfg.password;
    V_RISING_SERVER_GAME_PORT = toString cfg.gamePort;
    V_RISING_SERVER_QUERY_PORT = toString cfg.queryPort;
    V_RISING_SERVER_RCON_ENABLED = boolStr (cfg.rconPassword != "");
    V_RISING_SERVER_RCON_PORT = toString cfg.rconPort;
    V_RISING_SERVER_RCON_PASSWORD = cfg.rconPassword;
    V_RISING_SERVER_MAX_CONNECTED_USERS = toString cfg.maxUsers;
    V_RISING_SERVER_MAX_CONNECTED_ADMINS = toString cfg.maxAdmins;
    V_RISING_SERVER_LIST_ON_MASTER_SERVER = boolStr cfg.public;
    V_RISING_SERVER_LIST_ON_STEAM = boolStr cfg.public;
    V_RISING_SERVER_LIST_ON_EOS = boolStr cfg.public;
    V_RISING_SERVER_AUTO_SAVE_COUNT = toString cfg.autoSaveCount;
    V_RISING_SERVER_AUTO_SAVE_INTERVAL = toString cfg.autoSaveInterval;
    V_RISING_SERVER_GAME_SETTINGS_PRESET = cfg.preset;
    V_RISING_SERVER_DEFAULT_HOST_SETTINGS = boolStr cfg.defaultHostSettings;
    V_RISING_SERVER_DEFAULT_GAME_SETTINGS = boolStr cfg.defaultGameSettings;
    # Unity registers one allocator per job worker and dies past 2048 of them
    # ("0xc0000005" / wine stack overflow) on high-core hosts. Pinning the
    # count keeps the server alive regardless of how many cores it sees.
    V_RISING_SERVER_JOB_WORKER_COUNT = toString cfg.jobWorkerCount;
    # Rootless Podman already maps container root to the host user.
    PUID = "0";
    PGID = "0";
  }
  // cfg.extraEnvironment;

  envArgs = lib.concatMap (name: [
    "-e"
    "${name}=${environment.${name}}"
  ]) (builtins.attrNames environment);

  volumeArgs = [
    "-v"
    "${dataDir}/saves:/app/vrising"
    "-v"
    "${dataDir}/game:/steamcmd/vrising"
  ];

  portArgs = [
    "-p"
    "${toString cfg.gamePort}:${toString cfg.gamePort}/udp"
    "-p"
    "${toString cfg.queryPort}:${toString cfg.queryPort}/udp"
  ]
  ++ lib.optionals (cfg.rconPassword != "") [
    "-p"
    "${toString cfg.rconPort}:${toString cfg.rconPort}/tcp"
  ];

  serveArgs = [
    "--rm"
    "--replace"
    "--name"
    "vrising"
  ]
  ++ portArgs
  ++ volumeArgs
  ++ envArgs
  ++ [ cfg.image ];

  # Start mode 1 means "install or update, then exit": no ports, no world, just
  # the Steam download. Runs while the server is stopped, so `vrising update`
  # can force a real update even when the service itself skips update checks.
  updateArgs = [
    "--rm"
    "--replace"
    "--name"
    "vrising-update"
  ]
  ++ volumeArgs
  ++ envArgs
  ++ [
    "-e"
    "V_RISING_SERVER_START_MODE=1"
    cfg.image
  ];

  # The run line goes through a script rather than straight into ExecStart:
  # systemd's own quoting rules are not the shell's, and a server name with an
  # apostrophe in it would otherwise be mangled or refused.
  #
  # The inhibitor holds only for as long as podman stays in the foreground, so
  # the machine is free to sleep again the moment the server stops. `idle` is
  # deliberately not inhibited: the screen should still blank and lock, it is
  # only suspending that would cut the players off. A host running this needs
  # `services.logind.settings.Login.LidSwitchIgnoreInhibited = false`, since
  # logind ignores inhibitors for the lid by default.
  runner = pkgs.writeShellApplication {
    name = "vrising-server-run";
    text = ''
      exec ${pkgs.systemd}/bin/systemd-inhibit \
        --what=sleep:handle-lid-switch \
        --who="V Rising" \
        --why="Dedicated server has players connected" \
        --mode=block \
        ${pkgs.podman}/bin/podman run ${lib.escapeShellArgs serveArgs}
    '';
  };

  # Idle restart. Podman's --rm plus a fresh Wine boot is what actually clears
  # the drift; nothing here trims memory in place.
  maintenance = pkgs.writeShellApplication {
    name = "vrising-maintenance";
    runtimeInputs = [
      pkgs.systemd
      pkgs.podman
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
    ];
    text = ''
      systemctl --user is-active --quiet vrising.service || exit 0

      # Empty world? No count parsed means the RCON command is wrong or the
      # server is mid-boot; either way, do not touch it.
      if ! out=$(podman exec -i vrising /app/rcon.sh ${lib.escapeShellArg cfg.maintenance.playerCountCommand} 2>/dev/null); then
        echo "rcon unreachable; skipping restart"
        exit 0
      fi

      count=$(printf '%s' "$out" | grep -oE '[0-9]+' | head -1 || true)
      if [ -z "$count" ]; then
        echo "no player count in rcon output; skipping restart"
        exit 0
      fi
      if [ "$count" -ne 0 ]; then
        echo "$count player(s) connected; skipping restart"
        exit 0
      fi

      # The save version directory changes between game versions (v3, v4, ...),
      # so glob it rather than pinning one.
      newest=$(find ${lib.escapeShellArg "${dataDir}/saves/Saves"} \
        -type f -name 'AutoSave_*.save.gz' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -1 | cut -d' ' -f2- || true)

      if [ -z "$newest" ]; then
        echo "no autosave found; skipping restart"
        exit 0
      fi

      age=$(( $(date +%s) - $(stat -c %Y "$newest") ))
      if [ "$age" -gt ${toString cfg.maintenance.maxSaveAge} ]; then
        echo "newest autosave is ''${age}s old; skipping restart"
        exit 0
      fi

      echo "world empty, autosave ''${age}s old; restarting"
      exec systemctl --user restart vrising.service
    '';
  };

  # `vrising` for ad-hoc control: vrising logs -f, vrising restart, vrising rcon "..."
  control = pkgs.writeShellApplication {
    name = "vrising";
    runtimeInputs = [
      pkgs.systemd
      pkgs.podman
    ];
    text = ''
      case "''${1-status}" in
        start|stop|restart|status)
          exec systemctl --user "$1" vrising.service ;;
        logs)
          shift
          exec journalctl --user -u vrising.service "$@" ;;
        update)
          # Stop first: SteamCMD must not rewrite the install under a running
          # server. The update container exits on its own once Steam is done.
          was_running=no
          if systemctl --user is-active --quiet vrising.service; then
            was_running=yes
            systemctl --user stop vrising.service
          fi
          podman pull ${cfg.image}
          podman run ${lib.escapeShellArgs updateArgs}
          if [ "$was_running" = yes ]; then
            systemctl --user start vrising.service
          fi ;;
        shell)
          exec podman exec -it vrising /bin/bash ;;
        rcon)
          shift
          exec podman exec -i vrising /app/rcon.sh "$@" ;;
        *)
          echo "usage: vrising {start|stop|restart|status|logs|update|shell|rcon <command>}" >&2
          exit 64 ;;
      esac
    '';
  };
in
{
  options.theorem.home.gaming.vrising = {
    enable = lib.mkEnableOption "V Rising dedicated server (rootless Podman)";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/didstopia/vrising-server:latest";
      description = "Container image running the V Rising server under Wine.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "Games/vrising";
      description = ''
        Directory under $HOME holding server state. `saves/` keeps the world
        and settings JSON, `game/` keeps the Steam install (about 10 GB).
      '';
    };

    updateOnStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Verify the install against Steam on every start. Accurate, but it
        re-checks about 2 GB each time and stretches a restart to ten minutes.
        Left off, the server starts from the local copy in roughly a minute
        and still picks up new builds from the background update check; run
        `vrising update` to force one by hand.
      '';
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start the server on login. For a real 24/7 server the user also needs
        lingering enabled at system level (`users.users.<name>.linger = true`),
        or the service stops when the last session ends.
      '';
    };

    serverName = lib.mkOption {
      type = lib.types.str;
      default = "V Rising Server";
      description = "Name shown in the in-game server browser.";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Server description shown in the browser.";
    };

    saveName = lib.mkOption {
      type = lib.types.str;
      default = "world1";
      description = ''
        World save name. It becomes the directory name under
        `saves/Saves/v3/<saveName>`, which is also where an existing
        single-player save must be copied to be adopted.
      '';
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Server password, empty for none. This lands in the Nix store and is
        world-readable, so treat it as a doorbell, not a secret.
      '';
    };

    public = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "List the server publicly (master server, Steam and EOS browsers).";
    };

    preset = lib.mkOption {
      type = lib.types.str;
      default = "StandardPvE";
      example = "";
      description = ''
        Game settings preset: StandardPvE, StandardPvP, Hardcore, Duo, Solo
        and similar. Set to "" to use the editable ServerGameSettings.json
        instead; while a preset is set the server ignores that file.
      '';
    };

    maxUsers = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Maximum connected players.";
    };

    maxAdmins = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Maximum connected admins, on top of the player slots.";
    };

    gamePort = lib.mkOption {
      type = lib.types.port;
      default = 9876;
      description = "UDP game port.";
    };

    queryPort = lib.mkOption {
      type = lib.types.port;
      default = 9877;
      description = "UDP Steam query port. Must stay gamePort + 1.";
    };

    rconPort = lib.mkOption {
      type = lib.types.port;
      default = 9878;
      description = "TCP RCON port, published only when rconPassword is set.";
    };

    rconPassword = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        RCON password. Empty disables RCON and leaves its port unpublished,
        which is the right default for a port you do not want on the internet.
      '';
    };

    autoSaveCount = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Number of autosaves kept before the oldest is dropped.";
    };

    autoSaveInterval = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = "Seconds between autosaves.";
    };

    jobWorkerCount = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = ''
        Unity job worker threads. Keep it well under the core count on big
        CPUs; auto-detection there trips the ">2048 Allocators registered"
        crash.
      '';
    };

    defaultHostSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Rewrite ServerHostSettings.json from these options on every start.";
    };

    defaultGameSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Rewrite ServerGameSettings.json from these options on every start.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        V_RISING_SERVER_GAME_SETTINGS_OVERRIDES = ''{"CastleDecayRateModifier": 0.5}'';
      };
      description = "Extra V_RISING_SERVER_* variables, merged last.";
    };

    maintenance = {
      enable = lib.mkEnableOption "periodic restart of an idle server";

      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 05,17:00:00";
        description = ''
          When to consider a restart, in `systemd.time` calendar format. Each
          firing only checks; it restarts nothing unless every guard passes.
        '';
      };

      playerCountCommand = lib.mkOption {
        type = lib.types.str;
        default = "playerlist";
        description = ''
          RCON command whose output the guard scans for a player count.

          UNVERIFIED: the server was stopped when this was written, so the
          command name could not be probed. If it is wrong the guard reads no
          count and skips the restart, which is the safe direction, but the
          timer then never fires. Confirm with `vrising rcon playerlist` while
          the server runs and correct this if needed.
        '';
      };

      maxSaveAge = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = ''
          Restart only if the newest autosave is younger than this many
          seconds, so the world on disk is current. Keep it comfortably above
          `autoSaveInterval`, or the guard never sees a fresh enough save.
        '';
      };
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist the data directory when home.persistence is available.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && podmanEnabled) {
      assertions = [
        {
          assertion = cfg.queryPort == cfg.gamePort + 1;
          message = "theorem.home.gaming.vrising: queryPort must be gamePort + 1; the game client derives it.";
        }
      ];

      services.podman.enable = true;
      home.packages = [ control ];

      # Directories only - the container itself never starts from activation.
      home.activation.vrisingDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${dataDir}/saves"} ${lib.escapeShellArg "${dataDir}/game"}
      '';

      systemd.user.services.vrising = {
        Unit = {
          Description = "V Rising dedicated server (Podman)";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
          # Home Manager's sd-switch would otherwise restart this unit during
          # activation, and a restart here means a 60s podman stop plus a
          # multi-minute Wine boot - long enough to hang the rebuild and leave
          # a stale activation lock (see NEVER_DO_THIS.md). keep-old leaves a
          # running server alone; pick the new config up with
          # `vrising restart` when the world is empty.
          X-SwitchMethod = "keep-old";
        };
        Service = {
          # Steam download plus the first Wine boot are slow; a short start
          # timeout would kill the server before it ever finishes installing.
          TimeoutStartSec = "30min";
          TimeoutStopSec = "120";
          Restart = "always";
          RestartSec = "10";
          ExecStart = lib.getExe runner;
          ExecStop = "${pkgs.podman}/bin/podman stop --time 60 vrising";
        };
      };

      # Started by a timer, not WantedBy=default.target: as a wanted unit it
      # pulls network-online.target into the session's startup job, and the
      # login sits behind both that and podman's first seconds. The timer runs
      # outside that job, so the desktop comes up immediately.
      systemd.user.timers.vrising = lib.mkIf cfg.autoStart {
        Timer.OnStartupSec = "30s";
        Install.WantedBy = [ "timers.target" ];
      };

      # Every guard below exits 0 on anything unexpected. A missed restart is
      # invisible; one that lands on a populated world drops players and loses
      # whatever happened since the last autosave.
      systemd.user.services.vrising-maintenance = lib.mkIf cfg.maintenance.enable {
        Unit.Description = "Restart V Rising when the world is empty and saved";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe maintenance;
        };
      };

      systemd.user.timers.vrising-maintenance = lib.mkIf cfg.maintenance.enable {
        Timer = {
          OnCalendar = cfg.maintenance.onCalendar;
          Persistent = false;
          RandomizedDelaySec = "5m";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && podmanEnabled && cfg.persist) {
        # .local/share/containers (the image store) is persisted by
        # modules/home/base/virtualization.nix; declaring it twice is an error.
        directories = [ cfg.dataDir ];
      };
    })
  ];
}
