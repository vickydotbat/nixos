{
  config,
  lib,
  pkgs,
  ...
}:
# The second copy of the Shadows Over Westgate restic repositories.
#
# The primaries live in a Bunny Storage Zone (sow-platform ADR-0035). Bunny
# has no object lock, so a deletion there — malicious or tired — would leave
# no copy at all. This module makes each operator workstation pull an
# ADDITIVE `restic copy` of both hosts' repositories onto its own disk, daily
# (sow-platform ADR-0041, issue #105).
#
# `restic copy` only ever adds snapshots at the destination. That is the
# property this module exists for: a compromised primary can shrink itself,
# never the copies. Retention is decided HERE, on the workstation: after each
# copy we `forget --keep-daily 7 --keep-weekly 4 --prune` the local copy, so
# a daily pull does not stack up forever. The primary still cannot shrink the
# copies — the keep policy is local and only trims what the policy says.
#
# Credentials are decrypted at runtime from the sow-platform checkout with
# the operator age key (the workstations are recipients of every platform
# secret, ADR-0036). Nothing secret is copied into this repository, and a
# rotated credential is picked up by simply pulling the platform repo.
#
# The predecessor of this module (users/vicky/profiles/sow-backup.nix,
# removed in fc807ff) failed silently for weeks as a user timer. Hence:
# system units, Persistent timers, a FAILED marker on disk, and a weekly
# staleness check that fails loudly when the newest copy is over a week old.
let
  cfg = config.theorem.nixos.base.sowSecondCopy;

  copyScript = host: ''
    set -euo pipefail
    dest_root=${lib.escapeShellArg cfg.destRoot}
    dest="$dest_root/${host}"
    mkdir -p "$dest"

    # Refuse to fill the disk the operator works on. The copy failing is
    # recoverable; a full root filesystem on a workstation is a bad evening.
    free_gib="$(df -B1G --output=avail "$dest_root" | tail -1 | tr -dc '0-9')"
    if [ "''${free_gib:-0}" -lt ${toString cfg.minFreeGiB} ]; then
      echo "sow-copy-${host}: only ''${free_gib} GiB free under $dest_root (< ${toString cfg.minFreeGiB}); refusing" >&2
      exit 1
    fi

    # Decrypt the source credentials into a private tmpdir that dies with us.
    # The unit runs with PrivateTmp, so /tmp here is invisible to other users.
    export SOPS_AGE_KEY_FILE=${lib.escapeShellArg cfg.ageKeyFile}
    secdir="$(mktemp -d -t sow-copy.XXXXXX)"
    chmod 700 "$secdir"
    trap 'rm -rf "$secdir"' EXIT
    platform=${lib.escapeShellArg cfg.platformRepo}
    sops -d "$platform/infra/nixos/secrets/${host}/restic.env.sops" > "$secdir/env"
    sops -d "$platform/infra/nixos/secrets/${host}/restic-password.sops" > "$secdir/pw"
    set -a
    . "$secdir/env"
    set +a

    # First run: create the destination with the source's chunker parameters,
    # so copied data deduplicates instead of doubling.
    if [ ! -f "$dest/config" ]; then
      restic -r "$dest" --password-file "$secdir/pw" init \
        --copy-chunker-params \
        --from-repo "$RESTIC_REPOSITORY" --from-password-file "$secdir/pw"
    fi

    restic -r "$dest" --password-file "$secdir/pw" copy \
      --from-repo "$RESTIC_REPOSITORY" --from-password-file "$secdir/pw"

    # Trim the local copy so a daily pull does not stack up forever. This is
    # a local decision with local credentials; the primary cannot trigger it.
    restic -r "$dest" --password-file "$secdir/pw" forget \
      --keep-daily 7 --keep-weekly 4 --prune

    # Structural check of the local copy: cheap on local disk, and a copy
    # that does not verify is not a copy.
    restic -r "$dest" --password-file "$secdir/pw" check

    date -u +%Y-%m-%dT%H:%M:%SZ > "$dest_root/last-ok-${host}"
    rm -f "$dest_root/FAILED-${host}"
  '';

  mkCopyService = host: {
    name = "sow-copy-${host}";
    value = {
      description = "Additive restic copy of the ${host} repository (SoW second copy)";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      onFailure = [ "sow-copy-failed@${host}.service" ];
      path = [
        pkgs.restic
        pkgs.sops
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        # Run as the operator: the copies live in the operator's home
        # directory and the nixcfg group grants read access to the age key.
        User = "vicky";
        PrivateTmp = true;
        # A full first copy over a home connection can take hours.
        TimeoutStartSec = "12h";
      };
      script = copyScript host;
    };
  };

  mkCopyTimer = host: {
    name = "sow-copy-${host}";
    value = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "1h";
        # Workstations sleep and power off; catch up instead of skipping.
        Persistent = true;
      };
    };
  };
in
{
  options.theorem.nixos.base.sowSecondCopy = {
    enable = lib.mkEnableOption "daily additive copy of the SoW restic repositories onto this machine";

    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ovh-main"
        "netcup-game"
      ];
      description = "Source hosts whose repositories are copied; must match secret dirs in the platform repo.";
    };

    platformRepo = lib.mkOption {
      type = lib.types.str;
      default = "/home/vicky/Projects/westgate/sow-platform";
      description = "Checkout of sow-platform holding the encrypted restic credentials.";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist/secrets/sops/age/keys.txt";
      description = "Operator age key able to decrypt the platform secrets (ADR-0036 recipient).";
    };

    destRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/vicky/Backups/sow";
      description = "Directory holding one local restic repository per source host, plus the status markers.";
    };

    minFreeGiB = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Refuse to copy when the destination filesystem has less free space than this.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.listToAttrs (map mkCopyService cfg.hosts) // {
      # Failure leaves a marker file next to the repositories and shouts on
      # every terminal. Not subtle, by design: the predecessor of this unit
      # died silently for weeks.
      "sow-copy-failed@" = {
        description = "Record and announce a failed SoW copy for %i";
        serviceConfig = {
          Type = "oneshot";
          # Same owner as the copies, so the marker sits next to them.
          User = "vicky";
        };
        path = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        script = ''
          mkdir -p ${lib.escapeShellArg cfg.destRoot}
          date -u +%Y-%m-%dT%H:%M:%SZ > ${lib.escapeShellArg cfg.destRoot}/"FAILED-$1"
          wall "sow-copy-$1 FAILED: the second backup copy did not run. journalctl -u sow-copy-$1" || true
        '';
        scriptArgs = "%i";
      };

      sow-copy-stale = {
        description = "Warn when the newest SoW copy is over a week old";
        path = [
          pkgs.coreutils
          pkgs.util-linux
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -euo pipefail
          stale=0
          for host in ${lib.escapeShellArgs cfg.hosts}; do
            stamp=${lib.escapeShellArg cfg.destRoot}/"last-ok-$host"
            if [ ! -f "$stamp" ] || [ "$(( $(date +%s) - $(stat -c %Y "$stamp") ))" -gt $(( 8 * 86400 )) ]; then
              wall "sow-copy: the local copy of $host is missing or older than 8 days ($stamp)" || true
              stale=1
            fi
          done
          exit "$stale"
        '';
      };
    };

    systemd.timers = lib.listToAttrs (map mkCopyTimer cfg.hosts) // {
      sow-copy-stale = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    };
  };
}
