{
  config,
  lib,
  pkgs,
  ...
}:
# Weekly pull of Westgate production data from ovh-main into a local restic
# repository. This is the platform's off-VPS backup copy; see
# sow-platform/docs/superpowers/specs/2026-06-23-bunny-backup-obscure-path-design.md.
# ponytail: pulls straight from the host because the cloud primary (Bunny/B2)
# is still design-only; once that exists, replace the dump+rsync half with an
# additive `rclone copy` of the cloud repository.
let
  user = config.home.username;
  backupRoot = "/nix/persist/home/${user}/Backups/sow-restic";
  repo = "${backupRoot}/prod";
  passwordFile = "${backupRoot}/restic-password";
  staging = "${backupRoot}/staging";
  mirror = "${backupRoot}/state-mirror";

  remote = "ovh-main";
  remoteState = "/srv/nwn-prod/state";

  # Same coverage as sow-platform/infra/nixos/modules/restic.nix: consistent
  # dumps for databases, file state rsynced as-is. Live DB data dirs
  # (gitea/postgres, nodebb/mongo, nodebb/redis) are intentionally excluded —
  # copying them while running risks torn snapshots.
  statePaths = [
    "gitea/config"
    "gitea/data"
    "nodebb/config"
    "nodebb/uploads"
    "traefik"
    # Not deployed yet; picked up automatically once they exist on the host.
    "nwn"
  ];

  sowPullBackup = pkgs.writeShellApplication {
    name = "sow-pull-backup";
    # SC2029: variables in ssh command strings expand client-side — intended.
    excludeShellChecks = [ "SC2029" ];
    runtimeInputs = with pkgs; [
      coreutils
      openssh
      restic
      rsync
    ];
    text = ''
      umask 077

      repo=${lib.escapeShellArg repo}
      password_file=${lib.escapeShellArg passwordFile}
      staging=${lib.escapeShellArg staging}
      mirror=${lib.escapeShellArg mirror}
      remote=${lib.escapeShellArg remote}
      remote_state=${lib.escapeShellArg remoteState}

      if [[ ! -r "$password_file" ]]; then
        echo "Missing restic password file: $password_file" >&2
        echo "Generate it once (and store a copy in the password manager):" >&2
        echo "  umask 077 && openssl rand -base64 32 > $password_file" >&2
        exit 1
      fi

      export RESTIC_REPOSITORY="$repo"
      export RESTIC_PASSWORD_FILE="$password_file"

      if [[ ! -f "$repo/config" ]]; then
        restic init
      fi

      mkdir -p "$staging" "$mirror"

      has_container() {
        ssh "$remote" "docker ps --format '{{.Names}}' | grep -qx $1"
      }

      # Consistent database dumps, streamed over SSH. Fails loudly if an
      # expected container is down — a silent partial backup is worse.
      echo "Dumping gitea postgres..."
      ssh "$remote" 'docker exec sow-gitea-db pg_dump -U gitea -Fc gitea' \
        > "$staging/gitea.dump"

      echo "Dumping nodebb mongo..."
      ssh "$remote" "docker exec sow-nodebb-mongo sh -c \
        'mongodump --archive -u \"\$MONGO_INITDB_ROOT_USERNAME\" -p \"\$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin'" \
        > "$staging/nodebb-mongo.archive"

      echo "Dumping nodebb redis..."
      ssh "$remote" 'docker exec sow-nodebb-redis redis-cli SAVE >/dev/null &&
        docker exec sow-nodebb-redis cat /data/dump.rdb' \
        > "$staging/nodebb-redis-dump.rdb"

      if has_container sow-nwn-db; then
        echo "Dumping nwn postgres..."
        ssh "$remote" 'docker exec sow-nwn-db pg_dump -U postgres -Fc core' \
          > "$staging/nwn-core.dump"
      fi

      for f in "$staging"/*; do
        [[ -s "$f" ]] || { echo "Empty dump: $f" >&2; exit 1; }
      done

      # Additive mirror of file state (no --delete: an upstream wipe must not
      # propagate here on the next run, per the backup design spec).
      for path in ${lib.escapeShellArgs statePaths}; do
        if ssh "$remote" "sudo -n test -d $remote_state/$path"; then
          echo "Syncing $path..."
          mkdir -p "$mirror/$path"
          rsync -a --rsync-path='sudo rsync' \
            "$remote:$remote_state/$path/" "$mirror/$path/"
        else
          echo "Skipping absent remote path: $remote_state/$path"
        fi
      done

      restic backup --tag sow-prod "$staging" "$mirror"
      restic forget --keep-weekly 8 --keep-monthly 6 --prune
      restic check

      echo "Backup complete: $(restic snapshots --tag sow-prod --json | tail -c 200)"
    '';
  };
in
{
  home.packages = [ sowPullBackup ];

  systemd.user.services.sow-pull-backup = {
    Unit.Description = "Pull Westgate production backup from ovh-main into local restic repo";

    Service = {
      Type = "oneshot";
      ExecStart = "${sowPullBackup}/bin/sow-pull-backup";
    };
  };

  systemd.user.timers.sow-pull-backup = {
    Unit.Description = "Weekly Westgate production backup pull";

    Timer = {
      OnCalendar = "weekly";
      # Fire on next boot if the machine was off at the scheduled time.
      Persistent = true;
      Unit = "sow-pull-backup.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };
}
