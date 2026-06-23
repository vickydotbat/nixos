{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

# Vicky's Plasma working surface. The reusable Plasma module only enables
# Plasma Manager; layout, shortcuts, MIME defaults, KDE Connect, and wallet
# persistence live here because they are operator posture, not shared substrate.
let
  trashPath = "${config.home.homeDirectory}/.local/share/Trash";

  # Plasma 6 stores accepted output state here. This captures Solanine's
  # manually confirmed DisplayPort mode so the next activation does not drift
  # back to the monitor's 144 Hz preferred timing.
  solanineKwinOutputConfig = pkgs.writeText "solanine-kwinoutputconfig.json" (
    builtins.toJSON [
      {
        name = "outputs";
        data = [
          {
            allowDdcCi = true;
            allowSdrSoftwareBrightness = true;
            autoBrightnessCurve = [
              0
              0
              0
              0
              0
              0
            ];
            autoRotation = "InTabletMode";
            automaticBrightness = false;
            brightness = 1;
            colorPowerTradeoff = "PreferEfficiency";
            colorProfileSource = "sRGB";
            connectorName = "DP-2";
            customModes = [ ];
            detectedDdcCi = false;
            edidHash = "8d353588464c024908579c11d7992ad2";
            edidIdentifier = "ACR 1425 2449505196 20 2019 0";
            edrPolicy = "always";
            highDynamicRange = false;
            iccProfilePath = "";
            maxBitsPerColor = 0;
            mode = {
              flags = 0;
              height = 1080;
              refreshRate = 119982;
              width = 1920;
            };
            overscan = 0;
            rgbRange = "Automatic";
            scale = 1;
            sdrBrightness = 200;
            sdrGamutWideness = 0;
            sharpness = 0;
            transform = "Normal";
            uuid = "e786cb11-200e-4d4e-bac7-17673b9568a7";
            vrrPolicy = "Never";
            wideColorGamut = false;
          }
        ];
      }
      {
        name = "setups";
        data = [
          {
            lidClosed = false;
            outputs = [
              {
                enabled = true;
                outputIndex = 0;
                position = {
                  x = 0;
                  y = 0;
                };
                priority = 1;
                replicationSource = "";
              }
            ];
          }
        ];
      }
    ]
  );
in
{
  programs.plasma = {
    enable = true;

    panels = [
      {
        location = "top";
        height = 38;
        widgets = [
          {
            kickoff = {
              popupHeight = 509;
              popupWidth = 647;
              settings.General.favoritesPortedToKAstats = true;
            };
          }
          {
            pager.general = {
              showApplicationIconsOnWindowOutlines = true;
              navigationWrapsAround = true;
            };
          }
          "org.kde.plasma.mediacontroller"
          "org.kde.plasma.panelspacer"
          {
            iconTasks = {
              launchers = [ "preferred://filemanager" ];
              behavior = {
                sortingMethod = "byDesktop";
                showTasks.onlyInCurrentDesktop = false;
                grouping.method = "none";
              };
            };
          }
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              extra = [
                "org.kde.kdeconnect"
                "org.kde.plasma.cameraindicator"
                "org.kde.plasma.clipboard"
                "org.kde.plasma.devicenotifier"
                "org.kde.plasma.manage-inputmethod"
                "org.kde.plasma.notifications"
                "org.kde.plasma.battery"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.keyboardindicator"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
                "org.kde.plasma.weather"
                "org.kde.plasma.brightness"
                "org.kde.plasma.trash"
                "org.kde.kscreen"
              ];
              hidden = [
                "org.kde.plasma.brightness"
                "org.kde.plasma.trash"
                "org.kde.kscreen"
              ];
            };
          }
          {
            digitalClock = {
              settings = {
                popupHeight = 400;
                popupWidth = 560;
                Appearance.fontWeight = 400;
              };
            };
          }
        ];
      }
    ];

    shortcuts = {
      "KDE Keyboard Layout Switcher" = {
        "Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
        "Switch to Next Keyboard Layout" = "Meta+Alt+K";
      };

      kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";

      kwin = {
        "Activate Window Demanding Attention" = "Meta+Ctrl+A";
        "Edit Tiles" = "Meta+T";
        Expose = "Meta+F9";
        ExposeAll = [
          "Meta+F10"
          "Launch (C)"
        ];
        ExposeClass = "Meta+F7";
        "Grid View" = "Meta+G";
        "Kill Window" = "Meta+Ctrl+Esc";
        MoveMouseToCenter = "Meta+F6";
        MoveMouseToFocus = "Meta+F5";
        Overview = "Meta+W";
        "Show Desktop" = "Meta+D";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch Window Down" = "Meta+Alt+Down";
        "Switch Window Left" = "Meta+Alt+Left";
        "Switch Window Right" = "Meta+Alt+Right";
        "Switch Window Up" = "Meta+Alt+Up";
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";
        "Switch to Desktop 6" = "Meta+6";
        "Switch to Next Desktop" = "Meta+S";
        "Switch to Previous Desktop" = "Meta+A";
        "Walk Through Windows" = [
          "Meta+Tab"
          "Alt+Tab"
        ];
        "Walk Through Windows (Reverse)" = [
          "Meta+Shift+Tab"
          "Alt+Shift+Tab"
        ];
        "Walk Through Windows of Current Application" = [
          "Meta+`"
          "Alt+`"
        ];
        "Walk Through Windows of Current Application (Reverse)" = [
          "Meta+~"
          "Alt+~"
        ];
        "Window Close" = "Alt+F4";
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
        "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
        "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
        "Window Operations Menu" = "Alt+F3";
        "Window Quick Tile Bottom" = "Meta+Down";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window to Next Desktop" = "Meta+Shift+S";
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Desktop" = "Meta+Shift+A";
        "Window to Previous Screen" = "Meta+Shift+Left";
        disableInputCapture = "Meta+Shift+Esc";
        view_actual_size = "Meta+0";
        view_zoom_in = [
          "Meta++"
          "Meta+="
        ];
        view_zoom_out = "Meta+-";
      };

      plasmashell = {
        "activate application launcher" = [
          "Meta"
          "Alt+F1"
        ];
        "activate task manager entry 1" = [ ];
        "activate task manager entry 2" = [ ];
        "activate task manager entry 3" = [ ];
        "activate task manager entry 4" = [ ];
        "activate task manager entry 5" = [ ];
        "activate task manager entry 6" = [ ];
        clipboard_action = "Meta+Ctrl+X";
        cycle-panels = "Meta+Alt+P";
        "manage activities" = "Meta+Q";
        "show dashboard" = "Ctrl+F12";
        show-on-mouse-pos = "Meta+V";
      };

      "services/org.kde.spectacle.desktop" = {
        CurrentMonitorScreenShot = "Shift+Print";
        FullScreenScreenShot = "Meta+Shift+Print";
        OpenWithoutScreenshot = [ ];
        RectangularRegionScreenShot = "Print";
        WindowUnderCursorScreenShot = [ ];
        _launch = [ ];
      };
    };

    configFile = {
      "baloorc" = {
        "Basic Settings".Indexing-Enabled = true;

        General = {
          "only basic indexing" = true;
          "exclude folders[$e]" =
            "$HOME/.cache/,$HOME/.local/share/Trash/,$HOME/Downloads/,$HOME/.local/share/containers/,$HOME/.var/,$HOME/.steam/,$HOME/Games/,$HOME/.config/,$HOME/.local/share/baloo/";
        };
      };

      "dolphinrc" = {
        "KFileDialog Settings" = {
          "Places Icons Auto-resize" = false;
          "Places Icons Static Size" = 22;
        };

        MainWindow.MenuBar = "Disabled";

        PreviewSettings.Plugins = "appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,directorythumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,opendocumentthumbnail,svgthumbnail,windowsexethumbnail,windowsimagethumbnail,fontthumbnail,blenderthumbnail,ffmpegthumbs,gsthumbnail,mobithumbnail,rawthumbnail";
      };

      "kcminputrc".Keyboard = {
        RepeatDelay = 300;
        RepeatRate = 50;
      };

      "kded5rc".Module-device_automounter.autoload = false;

      "kdeglobals" = {
        General = {
          BrowserApplication = "firefox-devedition.desktop";
          UseSystemBell = true;
        };

        KDE = {
          AutomaticLookAndFeel = true;
          contrast = 4;
          frameContrast = 0.2;
        };

        "KFileDialog Settings" = {
          "Allow Expansion" = false;
          "Automatically select filename extension" = true;
          "Breadcrumb Navigation" = true;
          "Decoration position" = 2;
          "Show Full Path" = false;
          "Show Inline Previews" = true;
          "Show Preview" = false;
          "Show Speedbar" = true;
          "Show hidden files" = false;
          "Sort by" = "Name";
          "Sort directories first" = true;
          "Sort hidden files last" = false;
          "Sort reversed" = false;
          "Speedbar Width" = 140;
          "View Style" = "DetailTree";
        };

        PreviewSettings = {
          EnableRemoteFolderThumbnail = false;
          MaximumRemoteSize = 0;
        };

        WM = {
          activeBackground = "227,229,231";
          activeBlend = "227,229,231";
          activeForeground = "35,38,41";
          inactiveBackground = "239,240,241";
          inactiveBlend = "239,240,241";
          inactiveForeground = "112,125,138";
        };
      };

      "kiorc" = {
        Confirmations = {
          ConfirmDelete = true;
          ConfirmEmptyTrash = true;
          ConfirmTrash = false;
        };

        "Executable scripts".behaviourOnLaunch = "alwaysAsk";
      };

      "kservicemenurc".Show = {
        RunGhosttyDir = true;
        compressfileitemaction = true;
        extractfileitemaction = true;
        forgetfileitemaction = true;
        hidefileitemaction = false;
        installFont = true;
        kactivitymanagerd_fileitem_linking_plugin = true;
        kdeconnectfileitemaction = true;
        kio-admin = true;
        makefileactions = true;
        mountisoaction = true;
        movetonewfolderitemaction = true;
        runInKonsole = true;
        setfoldericonitemaction = true;
        slideshowfileitemaction = true;
        tagsfileitemaction = true;
        wallpaperfileitemaction = true;
      };

      "ksmserverrc".General.loginMode = "emptySession";

      "ktrashrc".${trashPath} = {
        # Keep Trash short-lived and size-bound.
        Days = 1;
        LimitReachedAction = 1;
        Percent = 5;
        UseSizeLimit = true;
        UseTimeLimit = true;
      };

      "kwalletrc".Wallet."First Use" = false;

      "kwinrc" = {
        Desktops = {
          Number = 6;
          Rows = 1;
        };

        Effect-slide = {
          HorizontalGap = 0;
          SlideBackground = false;
        };

        Plugins.shakecursorEnabled = false;
        Windows.RollOverDesktops = true;
        Xwayland.Scale = 1;
      };

      "plasma-localerc".Formats.LANG = "en_GB.UTF-8";

      "plasmaparc".General = {
        RaiseMaximumVolume = true;
        VolumeStep = 1;
      };

      "spectaclerc" = {
        General = {
          autoSaveImage = true;
          clipboardGroup = "PostScreenshotCopyImage";
          launchAction = "DoNotTakeScreenshot";
        };

        ImageSave = {
          imageFilenameTemplate = "<yyyy>/<MM>-<MMMM>/Screenshot_<title>_<yyyy><MM><dd>_<HH><mm><ss>";
          translatedScreenshotsFolder = "Screenshots";
        };

        VideoSave = {
          translatedScreencastsFolder = "Screencasts";
          videoFilenameTemplate = "<yyyy>/<MM>-<MMMM>/Screencast_<title>_<yyyy><MM><dd>_<HH><mm><ss>";
        };
      };
    };
  };

  services.kdeconnect.enable = true;

  home.activation.solanineKwinOutputConfig =
    lib.mkIf (osConfig != null && osConfig.networking.hostName == "solanine")
      (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -D -m 0644 ${solanineKwinOutputConfig} \
            ${config.xdg.configHome}/kwinoutputconfig.json
        ''
      );

  # Keep Plasma wallet, Baloo index, and KDE Connect pairing state across
  # impermanent boots when Vicky's Home persistence is enabled.
  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [
      ".local/share/kwalletd"
      ".local/share/baloo"
      ".config/kdeconnect"
    ];
  };

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = lib.mkForce [ "org.kde.dolphin.desktop" ];
    "application/pdf" = lib.mkForce [ "org.kde.okular.desktop" ];
    "image/png" = lib.mkForce [ "org.kde.gwenview.desktop" ];
    "image/jpeg" = lib.mkForce [ "org.kde.gwenview.desktop" ];
    "image/webp" = lib.mkForce [ "org.kde.gwenview.desktop" ];
  };
}
