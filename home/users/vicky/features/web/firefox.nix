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
        plasma-integration
        consent-o-matic
      ];

      settings = {
        # stop nagging me!
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.skipDefaultBrowserCheckOnFirstRun" = true;

        # needed for declarative extension installations
        "extensions.autoDisableScopes" = 0;

        # Downloads
        "browser.download.useDownloadDir" = true;
        "browser.download.always_ask_before_handling_new_types" = true;

        # Disable sync
        "identity.fxaccounts.enabled" = false;
        "identity.fxaccounts.toolbar.enabled" = false;
        "identity.fxaccounts.toolbar.defaultVisible" = false;

        # Disable "View on other devices..."
        "browser.tabs.firefox-view" = false;

        /*  -------------------
                Appearance
            ------------------- */

        # Enable new sidebar UI
        "sidebar.revamp" = true;

        # Enable native vertical tabs
        "sidebar.verticalTabs" = true;
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;

        # Right side instead of left
        "sidebar.position_start" = false;

        # Keep sidebar visible
        "sidebar.visibility" = "always-show";
        "sidebar.expandOnHover" = false;

        # Choose sidebar tools
        # Exact accepted values may change, but this keeps it minimal.
        "sidebar.main.tools" = "history,bookmarks";
        "sidebar.notification.badge.aichat" = false;
        "browser.ml.chat.sidebar" = false;

        # Show browser toolbar
        "browser.toolbars.bookmarks.visibility" = "always";

        /*  -------------------
            Privacy & Telemetry
            ------------------- */

        # Privacy-ish, without going full breakage mode
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.globalprivacycontrol.functionality.enabled" = true;

        # Total Cookie Protection
        "network.cookie.cookieBehavior" = 5;

        # Optional: reduces cross-site tracking further, but may break some flows.
        "privacy.partition.network_state" = true;

        # Disable Firefox telemetry/data reporting
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.sessions.current.clean" = true;

        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out" = true;
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";

        # Studies / Normandy / experiments
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";

        # Crash reports
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        # New tab / Activity Stream telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;

        # Sponsored / Mozilla suggestions
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;

        # Search telemetry-ish suggestions
        "browser.search.serpEventTelemetry.enabled" = false;
        "browser.search.update" = false;

        /*  -------------------
                Performance
            ------------------- */

        # Disk cache lives under ~/.cache/mozilla, which is tmpfs for you.
        # Keep it enabled but bounded.
        "browser.cache.disk.enable" = true;
        "browser.cache.disk.smart_size.enabled" = false;
        "browser.cache.disk.capacity" = 131072; # 128 MiB, in KiB

        # Memory cache is fine, but cap it too.
        "browser.cache.memory.enable" = true;
        "browser.cache.memory.capacity" = 65536; # 64 MiB, in KiB

        # Session restore writes into the persisted profile area.
        # Reduce write frequency so ~/.mozilla is less chatty.
        "browser.sessionstore.interval" = 60000; # 60 seconds

        # Keep less closed-tab/window restore history in the persisted profile.
        "browser.sessionstore.max_tabs_undo" = 5;
        "browser.sessionstore.max_windows_undo" = 1;

        # Page thumbnails are cache-like; avoid generating them.
        "browser.pagethumbnails.capturing_disabled" = true;
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
