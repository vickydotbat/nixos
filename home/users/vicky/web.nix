{ pkgs, config, ... }:

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

{
  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";

    profiles.vicky = {
      id = 0;
      name = "vicky";
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
      ];

      settings = {
        "extensions.autoDisableScopes" = 0;
      };
    };
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".config/mozilla/firefox"
    ];
  };
}
