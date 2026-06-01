{ pkgs, config, ... }:
let
  firefox = [ "firefox-devedition.desktop" ];
  profilePath = "${config.home.homeDirectory}/.mozilla/firefox/vicky";
in
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    configPath = ".mozilla/firefox";

    profiles.vicky = {
      id = 0;
      name = "vicky";
      path = "vicky";
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
      ".mozilla/firefox"
    ];
  };

  xdg.desktopEntries.firefox-devedition = {
    name = "Firefox Developer Edition";
    genericName = "Web Browser";
    exec = "${pkgs.firefox-devedition}/bin/firefox-devedition --name firefox-devedition --profile ${profilePath} %U";
    icon = "firefox-devedition";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  xdg.mimeApps = {
    enable = true;

    associations.added = {
      "text/html" = firefox;
      "text/xml" = firefox;
      "application/xhtml+xml" = firefox;
      "application/xml" = firefox;

      "x-scheme-handler/http" = firefox;
      "x-scheme-handler/https" = firefox;
      "x-scheme-handler/about" = firefox;
      "x-scheme-handler/unknown" = firefox;
    };

    defaultApplications = {
      "text/html" = firefox;
      "text/xml" = firefox;
      "application/xhtml+xml" = firefox;
      "application/xml" = firefox;

      "x-scheme-handler/http" = firefox;
      "x-scheme-handler/https" = firefox;
      "x-scheme-handler/about" = firefox;
      "x-scheme-handler/unknown" = firefox;
    };
  };
}
