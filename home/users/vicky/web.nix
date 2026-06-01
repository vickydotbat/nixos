{ pkgs, config, ... }:

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
