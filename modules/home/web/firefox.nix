{
  config,
  lib,
  options,
  osConfig ? null,
  pkgs,
  ...
}:
# Firefox Developer Edition is the daily browser profile in this theorem. Search
# defaults, repair shortcuts, and extension state live here so user files do not
# carry copied browser mechanics.
let
  cfg = config.theorem.home.web.firefox;
  hasHomePersistence = options.home ? persistence;
  desktopFile = "${cfg.desktopEntryName}.desktop";
  profileName = config.home.username;

  # Default browser target, shared by the desktop entry and MIME mappings.
  firefox = [ desktopFile ];
  profilePath = "${config.home.homeDirectory}/.mozilla/firefox/${profileName}";
  systemPlasmaBrowserIntegrationEnabled =
    if osConfig == null then
      false
    else
      (osConfig.theorem.nixos.desktop.plasma.enable or false)
      && (osConfig.theorem.nixos.desktop.plasma.browserIntegration.enable or false);
in
{
  options.theorem.home.web.firefox = {
    enable = lib.mkEnableOption "Firefox";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.firefox-devedition;
      description = "Firefox package installed and launched by this Home profile.";
    };

    desktopEntryName = lib.mkOption {
      type = lib.types.str;
      default = "firefox-devedition";
      description = "Desktop entry identifier used for Firefox MIME defaults.";
    };

    desktopName = lib.mkOption {
      type = lib.types.str;
      default = "Firefox Developer Edition";
      description = "Human-readable name shown by the generated Firefox desktop entry.";
    };

    icon = lib.mkOption {
      type = lib.types.str;
      default = "firefox-devedition";
      description = "Icon name used by the generated Firefox desktop entry.";
    };

    plasmaIntegration.enable = lib.mkOption {
      type = lib.types.bool;
      default = systemPlasmaBrowserIntegrationEnabled;
      defaultText = lib.literalExpression "system Plasma browser-integration connector state";
      description = ''
        Install the Firefox Plasma Integration extension when the native Plasma
        browser-integration connector is present. Standalone Home profiles may
        set this explicitly when another system provides that connector.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.firefox = {
        enable = true;
        package = cfg.package;
        configPath = ".mozilla/firefox";

        profiles.${profileName} = {
          id = 0;
          name = profileName;
          path = profileName;
          isDefault = true;

          extensions.packages =
            with pkgs.nur.repos.rycee.firefox-addons;
            [
              ublock-origin
              consent-o-matic
            ]
            ++ lib.optionals cfg.plasmaIntegration.enable [
              plasma-integration
            ];

          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
            order = [
              "ddg"
              "nix-packages"
              "nixos-options"
              "nixos-wiki"
              "google"
            ];

            engines = {
              nix-packages = {
                name = "Nix Packages";
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = [ "@np" ];
              };

              nixos-options = {
                name = "NixOS Options";
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = [ "@no" ];
              };

              nixos-wiki = {
                name = "NixOS Wiki";
                urls = [
                  {
                    template = "https://wiki.nixos.org/w/index.php";
                    params = [
                      {
                        name = "search";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                definedAliases = [ "@nw" ];
              };

              ddg.metaData.alias = "@d";
              google.metaData.alias = "@g";
              bing.metaData.hidden = true;
            };
          };

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

            # History kept brief
            "places.history.expiration.max_pages" = 5000;

            /*
              -------------------
              Appearance
              -------------------
            */

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

            /*
              -------------------
              Privacy & Telemetry
              -------------------
            */

            # Ensure Site Isolation is enabled
            "fission.autostart" = true;
            "gfx.webrender.all" = true;

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

            /*
              -------------------
              Performance
              -------------------
            */

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

      xdg.desktopEntries.${cfg.desktopEntryName} = {
        name = cfg.desktopName;
        genericName = "Web Browser";
        exec = "${lib.getExe cfg.package} --name ${cfg.desktopEntryName} --profile ${profilePath} %U";
        icon = cfg.icon;
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
        associations.added = {
          "text/html" = lib.mkForce firefox;
          "text/xml" = lib.mkForce firefox;
          "application/xhtml+xml" = lib.mkForce firefox;
          "application/xml" = lib.mkForce firefox;

          "x-scheme-handler/http" = lib.mkForce firefox;
          "x-scheme-handler/https" = lib.mkForce firefox;
          "x-scheme-handler/about" = lib.mkForce firefox;
          "x-scheme-handler/unknown" = lib.mkForce firefox;
        };

        defaultApplications = {
          "text/html" = lib.mkForce firefox;
          "text/xml" = lib.mkForce firefox;
          "application/xhtml+xml" = lib.mkForce firefox;
          "application/xml" = lib.mkForce firefox;

          "x-scheme-handler/http" = lib.mkForce firefox;
          "x-scheme-handler/https" = lib.mkForce firefox;
          "x-scheme-handler/about" = lib.mkForce firefox;
          "x-scheme-handler/unknown" = lib.mkForce firefox;
        };
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              ".mozilla/firefox"
            ];
          };
    })
  ];
}
