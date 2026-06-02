{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.gaming.nwn;

  # Default mechanism, kept in the reusable module; home/ may override it.
  nwnDataDir = "${config.home.homeDirectory}/.local/share/Neverwinter Nights";
  nwnDocumentsDir = "${config.home.homeDirectory}/Documents/Neverwinter Nights";
  windowsDocumentsDir = "C:\\users\\${config.home.username}\\Documents\\Neverwinter Nights";

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

in
{
  options.theorem.home.gaming.nwn.enable = lib.mkEnableOption "Neverwinter Nights tooling";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.blender-402-bin
      pkgs.cleanmodels
      pkgs.neverwinter-nim
      (pkgs.nwnexplorer.override {
        nwnInstallDir = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/Neverwinter Nights";
      })
    ];

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".local/share/Neverwinter Nights"
        ".config/blender/4.0"
      ];
    };

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
  };
}
