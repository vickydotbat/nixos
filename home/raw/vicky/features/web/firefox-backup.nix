{ config, pkgs, ... }:

/*
  Firefox sync places:
  - bookmarks and history: places.sqlite
  - favicons: favicons.sqlite
  - bookmark backups: compressed .jsonlz4 JSON backups in the bookmarkbackups folder
  - cookies.sqlite for the Cookies
  - formhistory.sqlite for saved autocomplete Form Data
  - logins.json (encrypted logins) and key4.db (encryption key/primary password) for logins saved in the Password Manager
  - cert9.db for certificates stored in the Certificate Manager
  - persdict.dat for words added to the spell checker dictionary
  - permissions.sqlite for Permissions and possibly content-prefs.sqlite for other website specific data (Site Preferences)
  - sessionstore.jsonlz4 for open tabs and pinned tabs (see also the sessionstore-backups folder)
*/

let
  user = config.home.username;
  # profileDir = "/nix/persist/home/${user}/.config/mozilla/firefox/vicky";
  profileDir = "/nix/persist/home/${user}/.mozilla/firefox/vicky";
  backupDir = "/nix/persist/home/${user}/Backups/firefox-state";
  identityFile = "/run/secrets/firefox-backup-age-identity";

  firefoxStateBackup = pkgs.writeShellApplication {
    name = "firefox-state-backup";
    runtimeInputs = with pkgs; [
      age
      coreutils
      findutils
      gnugrep
      gnused
      gnutar
    ];
    text = ''
      profile_dir=${pkgs.lib.escapeShellArg profileDir}
      backup_dir=${pkgs.lib.escapeShellArg backupDir}
      identity_file=${pkgs.lib.escapeShellArg identityFile}

      if [[ ! -d "$profile_dir" ]]; then
        echo "Firefox profile directory does not exist: $profile_dir" >&2
        exit 0
      fi

      if [[ ! -r "$identity_file" ]]; then
        echo "Firefox backup age identity is unavailable: $identity_file" >&2
        echo "Create and deploy secrets/solanine.yaml with firefox-backup-age-identity first." >&2
        exit 1
      fi

      recipient="$(age-keygen -y "$identity_file")"
      timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT

      mkdir -p "$tmp_dir/firefox-state" "$backup_dir"

      entries=(
        places.sqlite
        favicons.sqlite
        cookies.sqlite
        formhistory.sqlite
        logins.json
        key4.db
        cert9.db
        persdict.dat
        permissions.sqlite
        content-prefs.sqlite
        sessionstore.jsonlz4
        bookmarkbackups
        sessionstore-backups
      )

      for entry in "''${entries[@]}"; do
        if [[ -e "$profile_dir/$entry" ]]; then
          cp -a -- "$profile_dir/$entry" "$tmp_dir/firefox-state/"
        fi
      done

      if ! find "$tmp_dir/firefox-state" -mindepth 1 -print -quit | grep -q .; then
        echo "No selected Firefox state files exist in $profile_dir" >&2
        exit 0
      fi

      archive="$backup_dir/firefox-state-$timestamp.tar.age"
      tar -C "$tmp_dir" -cf - firefox-state | age -r "$recipient" -o "$archive"
      chmod 0600 "$archive"

      mapfile -t stale_archives < <(
        find "$backup_dir" -maxdepth 1 -type f -name 'firefox-state-*.tar.age' -printf '%T@ %p\n' \
          | sort -nr \
          | tail -n +8 \
          | sed 's/^[^ ]* //'
      )

      if (( "''${#stale_archives[@]}" > 0 )); then
        rm -f -- "''${stale_archives[@]}"
      fi

      echo "Wrote encrypted Firefox state backup: $archive"
    '';
  };

  firefoxStateRestore = pkgs.writeShellApplication {
    name = "firefox-state-restore";
    runtimeInputs = with pkgs; [
      age
      coreutils
      findutils
      gnused
      gnutar
    ];
    text = ''
      profile_dir=${pkgs.lib.escapeShellArg profileDir}
      backup_dir=${pkgs.lib.escapeShellArg backupDir}
      identity_file=${pkgs.lib.escapeShellArg identityFile}

      archive="''${1:-}"
      restore_dir="''${2:-$profile_dir}"

      if [[ -z "$archive" ]]; then
        archive="$(
          find "$backup_dir" -maxdepth 1 -type f -name 'firefox-state-*.tar.age' -printf '%T@ %p\n' 2>/dev/null \
            | sort -nr \
            | head -n 1 \
            | sed 's/^[^ ]* //'
        )"
      fi

      if [[ -z "$archive" || ! -f "$archive" ]]; then
        echo "No Firefox state backup archive found." >&2
        exit 1
      fi

      if [[ ! -r "$identity_file" ]]; then
        echo "Firefox backup age identity is unavailable: $identity_file" >&2
        exit 1
      fi

      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT

      age -d -i "$identity_file" "$archive" | tar -C "$tmp_dir" -xf -

      if [[ ! -d "$tmp_dir/firefox-state" ]]; then
        echo "Archive did not contain a firefox-state directory: $archive" >&2
        exit 1
      fi

      mkdir -p "$restore_dir"
      cp -a -- "$tmp_dir/firefox-state/." "$restore_dir/"

      echo "Restored Firefox state from $archive into $restore_dir"
      echo "Start Firefox after confirming no Firefox process is running during restore."
    '';
  };
in
{
  home.packages = [
    firefoxStateBackup
    firefoxStateRestore
  ];

  systemd.user.services.firefox-state-backup = {
    Unit.Description = "Back up selected Firefox state into an age-encrypted archive";

    Service = {
      Type = "oneshot";
      ExecStart = "${firefoxStateBackup}/bin/firefox-state-backup";
    };
  };

  systemd.user.timers.firefox-state-backup = {
    Unit.Description = "Run Firefox state backup after user manager startup";

    Timer = {
      OnBootSec = "2min";
      Persistent = true;
      Unit = "firefox-state-backup.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.firefox-state-backup-session = {
    Unit = {
      Description = "Back up selected Firefox state when the graphical session stops";
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = "${firefoxStateBackup}/bin/firefox-state-backup";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
