{
  config,
  lib,
  options,
  pkgs,
  ...
}:
# Neverwinter Nights keeps old path expectations alive on a modern Home profile.
# This module writes the alias files, links tool-specific data directories, and
# persists game state only when the user has selected Home persistence.
let
  cfg = config.theorem.home.gaming.nwn;
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);

  # Default mechanism, kept in the reusable module; home/ may override it.
  nwnInstallDir = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/Neverwinter Nights";
  nwnDataDir = "${config.home.homeDirectory}/.local/share/Neverwinter Nights";
  nwnDocumentsDir = "${config.home.homeDirectory}/Documents/Neverwinter Nights";
  winePrefixDir = "${config.home.homeDirectory}/.local/share/wineprefixes";
  windowsDocumentsDir = "C:\\users\\${config.home.username}\\Documents\\Neverwinter Nights";
  nwnBlender = pkgs.blender-402-bin;
  nwnBlenderConfigVersion = lib.versions.majorMinor nwnBlender.version;
  nwnexplorer = pkgs.nwnexplorer.override {
    inherit nwnInstallDir;
    winePrefix = "${winePrefixDir}/nwnexplorer";
  };
  nwtoolset = pkgs.nwtoolset.override {
    inherit nwnInstallDir;
    winePrefix = "${winePrefixDir}/nwtoolset";
  };

  nwnDataAliasesBeforeHome = [
    "CRASHREPORT"
    "MODELCOMPILER"
    "CACHE"
    "NWSYNC"
    "OLDSERVERVAULT"
    "PATCH"
    "DEVELOPMENT"
  ];

  nwnDataAliasesAfterHome = [
    "MODULES"
    "SAVES"
    "OVERRIDE"
    "HAK"
    "SCREENSHOTS"
    "CURRENTGAME"
    "LOGS"
    "TEMP"
    "TEMPCLIENT"
    "LOCALVAULT"
    "DMVAULT"
    "SERVERVAULT"
    "DATABASE"
    "PORTRAITS"
    "AMBIENT"
    "MOVIES"
    "MUSIC"
    "TLK"
  ];

  nwnAliases = [
    "MODULES"
    "SAVES"
    "OVERRIDE"
    "HAK"
    "SCREENSHOTS"
    "CURRENTGAME"
    "LOGS"
    "TEMP"
    "TEMPCLIENT"
    "LOCALVAULT"
    "DMVAULT"
    "SERVERVAULT"
    "DATABASE"
    "PORTRAITS"
    "AMBIENT"
    "MOVIES"
    "MUSIC"
    "TLK"
    "DEVELOPMENT"
    "PATCH"
    "OLDSERVERVAULT"
    "NWSYNC"
    "CACHE"
    "MODELCOMPILER"
    "CRASHREPORT"
  ];

  nwnDataIni = ''
    [Alias]
  ''
  + lib.concatMapStringsSep "\n" (
    alias: "${alias}=${nwnDataDir}/${lib.toLower alias}"
  ) nwnDataAliasesBeforeHome
  + ''

    HD0=${nwnDataDir}
  ''
  + lib.concatMapStringsSep "\n" (
    alias: "${alias}=${nwnDataDir}/${lib.toLower alias}"
  ) nwnDataAliasesAfterHome
  + "\n";

  nwnIni = ''
    [Alias]
    HD0=${windowsDocumentsDir}
  ''
  + lib.concatMapStringsSep "\n" (
    alias: "${alias}=${windowsDocumentsDir}\\${lib.toLower alias}"
  ) nwnAliases
  + "\n";

  nwnDirectories = [
    "ambient"
    "cache"
    "crashreport"
    "database"
    "development"
    "dmvault"
    "hak"
    "localvault"
    "logs"
    "modelcompiler"
    "modules"
    "movies"
    "music"
    "nwsync"
    "override"
    "portraits"
    "saves"
    "screenshots"
    "servervault"
    "temp"
    "tempclient"
    "tlk"
  ];
  # Neverblender runs its external decompiler with the working directory set to
  # the compiler's own directory (a Windows permissions workaround). cleanmodels
  # is SWI-Prolog and writes a last_dirs.pl state file into its cwd on startup,
  # so pointing Neverblender straight at the read-only profile binary fails with
  # "No permission to open source_sink `last_dirs.pl'". This wrapper steps into
  # a writable directory first. The name must keep "cleanmodels" in it, or
  # Neverblender will not recognize the compiler. Point the addon's Decompiler
  # Path at this wrapper, not at cleanmodels itself.
  cleanmodels-nvb = pkgs.writeShellApplication {
    name = "cleanmodels-nvb";
    text = ''
      cd "''${TMPDIR:-/tmp}"
      exec ${pkgs.cleanmodels}/bin/cleanmodels "$@"
    '';
  };
  nwn_unpack_folder = (
    pkgs.writeShellApplication {
      name = "nwn_unpack_folder";

      runtimeInputs = [
        pkgs.neverwinter-nim
      ];

      text = builtins.readFile ../../../scripts/nwn_unpack_folder;
    }
  );
in
{
  options.theorem.home.gaming.nwn.enable = lib.mkEnableOption "Neverwinter Nights tooling";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        pkgs.aurora-hak-explorer
        nwnBlender
        pkgs.cleanmodels
        cleanmodels-nvb
        pkgs.neverwinter-nim
        nwnexplorer
        nwtoolset
        nwn_unpack_folder
      ];

      home.activation.nwnDocumentsLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        nwn_data_dir=${lib.escapeShellArg nwnDataDir}
        nwn_documents_dir=${lib.escapeShellArg nwnDocumentsDir}
        nwn_directories=(${lib.escapeShellArgs nwnDirectories})

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$nwn_data_dir" "$nwn_documents_dir"

        for nwn_directory in "''${nwn_directories[@]}"; do
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$nwn_data_dir/$nwn_directory"
        done

        while IFS= read -r -d "" source_dir; do
          name="''${source_dir##*/}"
          target="$nwn_documents_dir/$name"

          if [[ -e "$target" && ! -L "$target" ]]; then
            echo "Skipping $target because it already exists and is not a symlink" >&2
            continue
          fi

          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$source_dir" "$target"
        done < <(${pkgs.findutils}/bin/find "$nwn_data_dir" -mindepth 1 -maxdepth 1 -type d -print0)

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 ${pkgs.writeText "nwn-data.ini" nwnDataIni} "$nwn_data_dir/nwn.ini"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 ${pkgs.writeText "nwn.ini" nwnIni} "$nwn_documents_dir/nwn.ini"
      '';
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && persistenceEnabled) {
        directories = [
          ".local/share/Neverwinter Nights"
          ".config/blender/${nwnBlenderConfigVersion}"
        ];
      };
    })
  ];
}
