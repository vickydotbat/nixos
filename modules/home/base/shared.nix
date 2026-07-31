{
  config,
  lib,
  options,
  osConfig ? null,
  pkgs,
  ...
}:

# A single shared folder that looks the same on every household machine.
#
# One host owns the real directory; the others reach it over SSH with sshfs.
# There is no new daemon, no new port and no new secret here: it rides the
# `vicky` key and the host aliases that already let these machines log into
# each other.
#
# ponytail: sshfs over the existing SSH trust beats standing up NFS or Samba
# for two laptops on one LAN. Move to a real file server if a third host, a
# non-SSH client, or large concurrent writes show up.
let
  cfg = config.theorem.home.base.shared;

  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);

  hostName = if osConfig == null then null else osConfig.networking.hostName;
  isOwner = hostName != null && hostName == cfg.host;

  mountPoint = "${config.home.homeDirectory}/${cfg.directory}";
  remote = "${cfg.host}:${cfg.remotePath}";

  # sshfs needs a live `ssh` on PATH, and user units do not inherit the login
  # PATH. Point it at the client explicitly instead.
  sshfsOptions = lib.concatStringsSep "," [
    "ssh_command=${lib.getExe pkgs.openssh}"
    # Survive the peer sleeping or the wifi dropping: sshfs reconnects instead
    # of leaving a dead mount that every `ls` hangs on.
    "reconnect"
    "ServerAliveInterval=15"
    "ServerAliveCountMax=3"
    "ConnectTimeout=10"
    # Without this a reconnect fails on any file handle opened before the drop.
    #
    # Keep it short. This is a folder two people edit from two machines, so a
    # stale size or mtime is worth more than the saved round trips: at 60s a
    # file changed on the owner could keep looking unchanged here for a minute.
    "cache_timeout=5"
  ];
in
{
  options.theorem.home.base.shared = {
    enable = lib.mkEnableOption "shared folder between household machines";

    host = lib.mkOption {
      type = lib.types.str;
      default = "solanine";
      description = ''
        Host that holds the real directory. Every other host mounts it from
        here, so this should be the machine that is most often awake. The name
        is used verbatim as an SSH destination, so it must match an alias in
        the user's SSH config.
      '';
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "Shared";
      description = "Path under the home directory, identical on every host.";
    };

    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "Shared";
      description = ''
        Path to the directory on the owning host, relative to the remote home
        directory. Only differs from `directory` if the owner keeps it
        somewhere else.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # The owner just keeps a directory. Nothing mounts, nothing can hang.
    (lib.mkIf isOwner {
      # ponytail: a plain mkdir, not `home.file."...".keep`. That would put a
      # /nix/store symlink inside the shared folder, and every client reading
      # it over sshfs fails with "Operation not permitted" on `ls -l`.
      home.activation.sharedDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountPoint}
      '';

      home.persistence = lib.mkIf (hasHomePersistence && persistenceEnabled) {
        "/nix/persist".directories = [ cfg.directory ];
      };
    })

    (lib.mkIf (!isOwner) {
      home.packages = [ pkgs.sshfs ];

      # `sshfs -f` stays in the foreground, so systemd can supervise it like any
      # other service. That avoids a `.mount` unit, which would need a
      # privileged `mount.fuse` helper this user does not have.
      systemd.user.services.shared-folder = {
        Unit = {
          Description = "Shared folder from ${cfg.host}";
          After = [ "network.target" ];
        };

        Service = {
          Type = "simple";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountPoint}";
          ExecStart = lib.concatStringsSep " " [
            "${lib.getExe pkgs.sshfs}"
            "-f"
            "-o ${sshfsOptions}"
            (lib.escapeShellArg remote)
            (lib.escapeShellArg mountPoint)
          ];
          # Unmount on stop, otherwise the mount point is left as a stale FUSE
          # endpoint that reports "Transport endpoint is not connected".
          #
          # sshfs is FUSE 3, so this must be `fusermount3`; the FUSE 2
          # `fusermount` fails with "Operation not permitted" and leaves the
          # mount behind. It has to be the setuid wrapper rather than the store
          # path for the same reason: unmounting as a normal user needs it.
          # `programs.fuse.enable` provides the wrapper.
          ExecStopPost = "-/run/wrappers/bin/fusermount3 -u ${lib.escapeShellArg mountPoint}";
          # The peer is a laptop and is often simply off. Keep retrying quietly
          # rather than failing the unit for the rest of the session.
          Restart = "always";
          RestartSec = 30;
        };

        Install.WantedBy = [ "default.target" ];
      };
    })
  ]);
}
