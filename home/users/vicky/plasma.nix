{ ... }:

{
  programs.plasma = {
    enable = true;

    panels = [
      {
        location = "top";
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
      "kcminputrc".Keyboard = {
        RepeatDelay = 300;
        RepeatRate = 50;
      };

      "kded5rc".Module-device_automounter.autoload = false;

      "kdeglobals" = {
        General.UseSystemBell = true;

        KDE = {
          AutomaticLookAndFeel = true;
          contrast = 4;
          frameContrast = 0.2;
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

      "ksmserverrc".General.loginMode = "emptySession";

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
}
